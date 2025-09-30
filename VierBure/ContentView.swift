import SwiftUI
import UIKit

// MARK: - Model
struct RoundScore: Hashable {
    var top: Int? = nil
    var bottom: Int? = nil
}

struct Player: Identifiable, Hashable {
    let id: UUID = UUID()
    var name: String
    // Two values per round (top & bottom)
    var scores: [RoundScore] = []
}

// MARK: - ViewModel
@MainActor
final class ScoreboardViewModel: ObservableObject {
    @Published var players: [Player]
    @Published var rounds: Int

    // Currently selected cell for quick input (affects bottom value)
    @Published var selected: (round: Int, playerIndex: Int)? = nil

    private let namesDefaultsKey = "Scoreboard.AllNames"
    private let matchTopValue = -257
    @Published var allNames: [String]

    init(playerCount: Int = 4) {
        let defaultNames = ["Spieler 1", "Spieler 2", "Spieler 3", "Spieler 4", "Spieler 5", "Spieler 6"]
        // Load persisted names or fall back to defaults, always keep exactly 6 entries
        let saved = UserDefaults.standard.stringArray(forKey: "Scoreboard.AllNames")
        var loaded = saved ?? defaultNames
        if loaded.count < 6 { loaded.append(contentsOf: defaultNames.dropFirst(loaded.count)) }
        if loaded.count > 6 { loaded = Array(loaded.prefix(6)) }
        self.allNames = loaded

        let count = min(max(3, playerCount), 6)
        let players = (0..<count).map { i in Player(name: loaded[i], scores: []) }
        self.players = players
        self.rounds = 0 // Start with zero rows
        ensureScoreCapacity()
        // Persist back to ensure key exists
        UserDefaults.standard.set(self.allNames, forKey: namesDefaultsKey)
    }

    // MARK: - Helpers
    func ensureScoreCapacity() {
        for i in players.indices {
            if players[i].scores.count < rounds {
                players[i].scores.append(contentsOf: Array(repeating: RoundScore(), count: rounds - players[i].scores.count))
            } else if players[i].scores.count > rounds {
                players[i].scores = Array(players[i].scores.prefix(rounds))
            }
        }
    }

    func setPlayerCount(_ count: Int) {
        let clamped = min(max(3, count), 6)
        if clamped > players.count {
            // Add new players with their persisted names and correct score capacity
            let newOnes = (players.count..<clamped).map { i in Player(name: allNames[i], scores: Array(repeating: RoundScore(), count: rounds)) }
            players.append(contentsOf: newOnes)
        } else if clamped < players.count {
            // Reduce visible players but keep names in allNames so they reappear later
            players = Array(players.prefix(clamped))
        }
        selected = nil
    }

    func addRound() { rounds += 1; ensureScoreCapacity() }
    func removeLastRound() { rounds = max(0, rounds - 1); ensureScoreCapacity() }
    func resetScores() {
        rounds = 0 // Reset rounds to zero
        for i in players.indices { players[i].scores = [] } // Clear all scores
        selected = nil
        ensureScoreCapacity() // Ensure consistency
    }

    func setName(_ name: String, for index: Int) {
        guard players.indices.contains(index) else { return }
        players[index].name = name
        if index < allNames.count { allNames[index] = name } else if index < 6 { allNames.append(name) }
        UserDefaults.standard.set(allNames, forKey: namesDefaultsKey)
    }

    // MARK: - Bindings
    func topBinding(round r: Int, player p: Int) -> Binding<String> {
        Binding<String>(
            get: {
                if self.players.indices.contains(p), r < self.players[p].scores.count, let v = self.players[p].scores[r].top { return String(v) }
                return "0"
            },
            set: { newValue in
                let trimmed = newValue.trimmingCharacters(in: .whitespaces)
                if trimmed.isEmpty { self.players[p].scores[r].top = 0; return }
                if let v = Int(trimmed) { 
                    // Limit to 3 digits: -999 to 999
                    let clamped = max(-999, min(999, v))
                    self.players[p].scores[r].top = clamped 
                } else { 
                    /* ignore non-number */ 
                }
            }
        )
    }

    func bottomValue(round r: Int, player p: Int) -> Int? {
        guard players.indices.contains(p), r < players[p].scores.count else { return nil }
        return players[p].scores[r].bottom
    }

    // MARK: - Bottom adjustments (special fields)
    func adjustBottomSelected(by delta: Int) {
        guard let sel = selected else { return }
        let r = sel.round
        let p = sel.playerIndex
        let value = (players[p].scores[r].bottom ?? 0) + delta
        players[p].scores[r].bottom = value
    }

    func clearBottomSelected() {
        guard let sel = selected else { return }
        players[sel.playerIndex].scores[sel.round].bottom = nil
    }

    func fillTopRestTo157() {
        guard let sel = selected else { return }
        let r = sel.round
        let p = sel.playerIndex
        // Sum all top values in this round except the selected player's current value
        var sumOthers = 0
        for (idx, pl) in players.enumerated() where idx != p {
            sumOthers += pl.scores[r].top ?? 0
        }
        let remainder = max(0, 157 - sumOthers)
        players[p].scores[r].top = remainder
    }
    
    func setTopSelectedToMatch() {
        guard let sel = selected else { return }
        let r = sel.round
        let p = sel.playerIndex
        // Set to a high negative value to indicate a "match" (losing all points)
        players[p].scores[r].top = matchTopValue
    }

    // MARK: - Row state helpers
    func isRowEditable(_ r: Int) -> Bool {
        return r == rounds - 1
    }

    private func hasAnyTopValue(in round: Int) -> Bool {
        players.contains { p in
            round < p.scores.count && p.scores[round].top != nil
        }
    }
    
    private func hasMatch(in round: Int) -> Bool {
        players.contains { p in
            round < p.scores.count && p.scores[round].top == matchTopValue
        }
    }

    func isRowInvalid(_ r: Int) -> Bool {
        // Only validate completed/previous rounds (there exists a newer round)
        guard r < rounds - 1 else { return false }
        
        // Special case: a 'Match' (-257) makes the round valid regardless of sum
        if hasMatch(in: r) { return false }

        // Calculate sum of top values in this round
        let sumTop = players.reduce(0) { partial, p in
            partial + (r < p.scores.count ? (p.scores[r].top ?? 0) : 0)
        }
        
        // Row is invalid if sum doesn't equal 157 (regardless of whether values were entered)
        return sumTop != 157
    }

    // Totals are sum of top+bottom per round
    var totals: [Int] {
        players.map { player in
            player.scores.reduce(0) { partial, rs in
                partial + (rs.top ?? 0) + (rs.bottom ?? 0)
            }
        }
    }
}

// MARK: - ContentView
@MainActor struct ContentView: View {
    @StateObject private var vm = ScoreboardViewModel()

    @State private var showNames = false
    @State private var showPlayerCount = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                headerRow
                    .padding(.horizontal, 8)
                Divider()
                    .padding(.horizontal, 8)
                table
                    .padding(.horizontal, 8)
            }
            .padding(.bottom)
            .navigationTitle("Vier Bure")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu("Menü") {
                        Button(role: .destructive) { vm.resetScores() } label: { Label("Punkte zurücksetzen", systemImage: "trash") }
                        Button { showNames = true } label: { Label("Namen eingeben", systemImage: "pencil") }
                        Button { showPlayerCount = true } label: { Label("Spieleranzahl ändern", systemImage: "person.3") }
                    }
                }
            }
            .sheet(isPresented: $showNames) { NamesSheet(vm: vm) }
            .sheet(isPresented: $showPlayerCount) { PlayerCountSheet(count: vm.players.count) { vm.setPlayerCount($0) } }
        }
        .safeAreaInset(edge: .bottom) {
            totalsRow
                .padding(.horizontal, 8)
                .padding(.top, 8)
                .background(.bar)
        }
    }

    private var table: some View {
        ScrollView {
            VStack(spacing: 8) {
                ForEach(0..<vm.rounds, id: \.self) { r in
                    scoreRow(for: r)
                }
                roundControls
                Spacer(minLength: 10)
            }
            .animation(.default, value: vm.players)
            .animation(.default, value: vm.rounds)
            .padding(.bottom, 12)
            .contentShape(Rectangle())
            .onTapGesture {
                dismissKeyboard()
                vm.selected = nil
            }
        }
    }
    
    private func scoreRow(for round: Int) -> some View {
        let isEditable = vm.isRowEditable(round)
        let isInvalid = vm.isRowInvalid(round)
        let isCompleted = !isEditable && !isInvalid && round < vm.rounds - 1 // Previous round with correct sum
        
        return HStack(spacing: 0) {
            // Round number with state color indication (left side)
            ZStack {
                Text("\(round + 1)")
                    .font(.caption2.weight(isInvalid ? .semibold : .regular))
                    .foregroundStyle(
                        isInvalid ? .red : 
                        isCompleted ? .green :
                        isEditable ? .blue : .secondary
                    )
            }
            .frame(width: 20, alignment: .center)
            
            HStack(spacing: 6) {
                ForEach(Array(vm.players.enumerated()), id: \.element.id) { (idx, _) in
                    scoreCell(round: round, playerIndex: idx, isEditable: isEditable, isRowInvalid: isInvalid)
                }
            }
            
            // Right spacer for symmetry with state icons
            ZStack {
                // State indicator icons
                if isInvalid {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.red)
                        .opacity(0.9)
                        .animation(.easeInOut(duration: 0.2), value: isInvalid)
                } else if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.green)
                        .opacity(0.8)
                        .animation(.easeInOut(duration: 0.2), value: isCompleted)
                } else if isEditable {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.blue)
                        .opacity(0.8)
                        .animation(.easeInOut(duration: 0.2), value: isEditable)
                }
            }
            .frame(width: 20, alignment: .center)
        }
        .padding(.vertical, 2)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(
                    // Only show background for error cases
                    isInvalid ? 
                    AnyShapeStyle(LinearGradient(
                        colors: [Color.red.opacity(0.06), Color.red.opacity(0.02)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ).opacity(0.7)) : 
                    AnyShapeStyle(Color.clear)
                )
        )
        .accessibilityHint(
            isInvalid ? "Fehler: Summe oben ist nicht 157" :
            isCompleted ? "Runde korrekt abgeschlossen" :
            isEditable ? "Aktive Runde - kann bearbeitet werden" : ""
        )
    }
    
    private func scoreCell(round: Int, playerIndex: Int, isEditable: Bool, isRowInvalid: Bool) -> some View {
        DoubleScoreCell(
            topText: vm.topBinding(round: round, player: playerIndex),
            isEnabled: isEditable,
            bottomValue: vm.bottomValue(round: round, player: playerIndex),
            isSelected: vm.selected?.round == round && vm.selected?.playerIndex == playerIndex,
            onSelect: { 
                vm.selected = (round: round, playerIndex: playerIndex)
            },
            onPlus20: { vm.adjustBottomSelected(by: 20) },
            onPlus50: { vm.adjustBottomSelected(by: 50) },
            onPlus100: { vm.adjustBottomSelected(by: 100) },
            onMinus20: { vm.adjustBottomSelected(by: -20) },
            onMinus50: { vm.adjustBottomSelected(by: -50) },
            onMinus100: { vm.adjustBottomSelected(by: -100) },
            onClear: { vm.clearBottomSelected() },
            onRest: { vm.fillTopRestTo157() },
            onMatch: { vm.setTopSelectedToMatch() },
            onDone: { dismissKeyboard() }
        )
        .frame(maxWidth: .infinity)
    }
    
    private var roundControls: some View {
        HStack {
            Button {
                vm.removeLastRound()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "minus.circle")
                    Text("Runde")
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                }
            }

            Spacer()

            Button {
                dismissKeyboard()
                vm.selected = nil
                vm.addRound()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle")
                    Text("Runde")
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                }
            }
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .padding(.top, 4)
    }

    private var headerRow: some View {
        HStack(spacing: 0) {
            Spacer(minLength: 20).frame(width: 20)
            HStack(spacing: 6) {
                ForEach(Array(vm.players.enumerated()), id: \.element.id) { (_, player) in
                    Text(player.name)
                        .font(.caption2.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(8)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
            Spacer(minLength: 20).frame(width: 20) // Right-side gap to align with icon column in score rows
        }
        .accessibilityElement(children: .contain)
    }

    private var totalsRow: some View {
        let totals = vm.totals
        let maxTotal = totals.max() ?? 0
        let minTotal = totals.min() ?? 0
        let allZero = totals.allSatisfy { $0 == 0 }
        return AnyView(
            HStack(spacing: 0) {
                Spacer(minLength: 20).frame(width: 20)
                HStack(spacing: 6) {
                    ForEach(Array(totals.enumerated()), id: \.offset) { _, value in
                        Text("\(value)")
                            .font(.body.monospacedDigit().weight(.semibold))
                            .foregroundStyle(allZero ? Color.primary : (value == minTotal ? Color.green : (value == maxTotal ? Color.red : Color.primary)))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(Color.secondary.opacity(0.08))
                            )
                    }
                }
                Spacer(minLength: 20).frame(width: 20)
            }
        )
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Reusable Views
private struct DoubleScoreCell: View {
    @Binding var topText: String
    var isEnabled: Bool
    var bottomValue: Int?
    var isSelected: Bool
    var onSelect: () -> Void

    var onPlus20: () -> Void
    var onPlus50: () -> Void
    var onPlus100: () -> Void
    var onMinus20: () -> Void
    var onMinus50: () -> Void
    var onMinus100: () -> Void
    var onClear: () -> Void
    var onRest: () -> Void
    var onMatch: () -> Void
    var onDone: () -> Void

    @State private var shouldFocus: Bool = false

    var body: some View {
        VStack(spacing: 4) {
            ScoreTextField(
                text: $topText,
                shouldFocus: $shouldFocus,
                isEnabled: isEnabled,
                onSelect: onSelect,
                onPlus20: onPlus20,
                onPlus50: onPlus50,
                onPlus100: onPlus100,
                onMinus20: onMinus20,
                onMinus50: onMinus50,
                onMinus100: onMinus100,
                onClearBottom: onClear,
                onRest: onRest,
                onMatch: onMatch,
                onDone: onDone
            )
            .frame(maxWidth: .infinity)

            Text("\(bottomValue ?? 0)")
                .font(.caption2.monospacedDigit())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.secondary.opacity(0.06))
                )
        }
        .padding(6)
        .opacity(isEnabled ? 1 : 0.6)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(isSelected ? Color.accentColor : Color.secondary.opacity(0.25), lineWidth: isSelected ? 2 : 1)
        )
        .onTapGesture { 
            if isEnabled { 
                shouldFocus = true
                onSelect()
            } 
        }
    }
}

// MARK: - Custom Keyboard
private struct CustomScoreKeyboard: View {
    let onDigit: (Int) -> Void
    let onDelete: () -> Void
    let onPlus20: () -> Void
    let onPlus50: () -> Void
    let onPlus100: () -> Void
    let onMinus20: () -> Void
    let onMinus50: () -> Void
    let onMinus100: () -> Void
    let onClearBottom: () -> Void
    let onRest: () -> Void
    let onMatch: () -> Void
    let onDone: () -> Void

    var body: some View {
        GeometryReader { proxy in
            let config = KeyboardConfiguration(width: proxy.size.width)
            
            VStack(spacing: config.spacing) {
                // MARK: Number row
                HStack(spacing: config.spacing) {
                    ForEach(["1","2","3","4","5","6","7","8","9","0"], id: \.self) { digit in
                        KeyboardButton(
                            text: digit,
                            style: .digit,
                            config: config,
                            action: { if let v = Int(digit) { tapDigit(v) } }
                        )
                    }
                }
                .frame(height: config.digitKeyHeight)

                // MARK: Plus row  
                HStack(spacing: config.spacing) {
                    KeyboardButton(text: "+20", style: .increment, config: config) { tap(onPlus20) }
                    KeyboardButton(text: "+50", style: .increment, config: config) { tap(onPlus50) }
                    KeyboardButton(text: "+100", style: .increment, config: config) { tap(onPlus100) }
                    KeyboardButton(text: "+150", style: .increment, config: config) { tap { onPlus100(); onPlus50() } }
                }
                .frame(height: config.keyHeight)

                // MARK: Minus row
                HStack(spacing: config.spacing) {
                    KeyboardButton(text: "−20", style: .decrement, config: config) { tap(onMinus20) }
                    KeyboardButton(text: "−50", style: .decrement, config: config) { tap(onMinus50) }
                    KeyboardButton(text: "−100", style: .decrement, config: config) { tap(onMinus100) }
                    KeyboardButton(text: "−150", style: .decrement, config: config) { tap { onMinus100(); onMinus50() } }
                }
                .frame(height: config.keyHeight)

                // MARK: Actions row
                HStack(spacing: config.spacing) {
                    KeyboardButton(text: "Fertig", style: .control, config: config) { tap(onDone) }
                    KeyboardButton(text: "Rest", style: .special, config: config) { tap(onRest) }
                    KeyboardButton(text: "Match", style: .success, config: config) { tap(onMatch) }
                    KeyboardButton(
                        systemImage: "delete.left.fill",
                        style: .control,
                        config: config,
                        accessibilityLabel: "Löschen"
                    ) { tap(onDelete) }
                }
                .frame(height: config.keyHeight)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(config.containerPadding)
            .background {
                // Enhanced Liquid Glass background
                ZStack {
                    // Primary blur material
                    Rectangle()
                        .fill(Material.bar)
                        .ignoresSafeArea(edges: .all)
                    
                    // Subtle gradient overlay for depth
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.02),
                            Color.clear,
                            Color.black.opacity(0.01)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea(edges: .all)
                }
            }
        }
    }

    private func tap(_ action: () -> Void) {
        action()
    }

    private func tapDigit(_ d: Int) {
        onDigit(d)
    }
}

// MARK: - Keyboard Configuration
private struct KeyboardConfiguration {
    let spacing: CGFloat
    let keyHeight: CGFloat
    let digitKeyHeight: CGFloat
    let cornerRadius: CGFloat
    let containerPadding: CGFloat
    let digitFont: Font
    let keyFont: Font
    
    init(width: CGFloat) {
        switch width {
        case ..<340:  // iPhone SE
            spacing = 4
            keyHeight = 48
            digitKeyHeight = 44  // Slightly larger like Apple keyboard
            cornerRadius = 8
            containerPadding = 8
            digitFont = .system(size: 18, weight: .medium, design: .rounded)
            keyFont = .system(size: 15, weight: .medium)
        case ..<390:  // Standard iPhone
            spacing = 6
            keyHeight = 52
            digitKeyHeight = 44  // Slightly larger like Apple keyboard
            cornerRadius = 10
            containerPadding = 12
            digitFont = .system(size: 20, weight: .medium, design: .rounded)
            keyFont = .system(size: 16, weight: .medium)
        case ..<768:  // Large iPhone
            spacing = 8
            keyHeight = 56
            digitKeyHeight = 44  // Slightly larger like Apple keyboard
            cornerRadius = 12
            containerPadding = 16
            digitFont = .system(size: 22, weight: .medium, design: .rounded)
            keyFont = .system(size: 17, weight: .medium)
        default:      // iPad
            spacing = 10
            keyHeight = 64
            digitKeyHeight = 48  // Slightly larger like Apple keyboard for iPad
            cornerRadius = 14
            containerPadding = 20
            digitFont = .system(size: 24, weight: .medium, design: .rounded)
            keyFont = .system(size: 18, weight: .medium)
        }
    }
}

// MARK: - Keyboard Button
private struct KeyboardButton: View {
    let text: String?
    let systemImage: String?
    let style: KeyboardButtonStyle
    let config: KeyboardConfiguration
    let accessibilityLabel: String?
    let action: () -> Void
    
    @State private var isPressed = false
    
    init(
        text: String,
        style: KeyboardButtonStyle,
        config: KeyboardConfiguration,
        accessibilityLabel: String? = nil,
        action: @escaping () -> Void
    ) {
        self.text = text
        self.systemImage = nil
        self.style = style
        self.config = config
        self.accessibilityLabel = accessibilityLabel
        self.action = action
    }
    
    init(
        systemImage: String,
        style: KeyboardButtonStyle,
        config: KeyboardConfiguration,
        accessibilityLabel: String? = nil,
        action: @escaping () -> Void
    ) {
        self.text = nil
        self.systemImage = systemImage
        self.style = style
        self.config = config
        self.accessibilityLabel = accessibilityLabel
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Primary background with Liquid Glass effect
                RoundedRectangle(cornerRadius: keyCornerRadius, style: .continuous)
                    .fill(backgroundMaterial)
                    .overlay {
                        // Subtle inner highlight for glass effect
                        RoundedRectangle(cornerRadius: keyCornerRadius, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(isPressed ? 0.1 : 0.25),
                                        Color.clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.5
                            )
                    }
                    .shadow(
                        color: shadowColor,
                        radius: isPressed ? 0 : 1.5,
                        x: 0,
                        y: isPressed ? 0 : 0.5
                    )
                
                // Content with enhanced styling
                if let text = text {
                    Text(text)
                        .font(style == .digit ? config.digitFont : config.keyFont)
                        .monospacedDigit()
                        .foregroundStyle(textColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .shadow(color: .black.opacity(0.05), radius: 0.5, x: 0, y: 0.5)
                } else if let systemImage = systemImage {
                    Image(systemName: systemImage)
                        .font(config.keyFont.weight(.medium))
                        .foregroundStyle(textColor)
                        .shadow(color: .black.opacity(0.05), radius: 0.5, x: 0, y: 0.5)
                }
            }
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isPressed)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .buttonStyle(PlainButtonStyle())
        .contentShape(Rectangle())
        .onPressedChange { pressed in
            isPressed = pressed
            // Enhanced haptic feedback based on button type
            if pressed {
                switch style {
                case .digit:
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                case .special, .success:
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                default:
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }
        }
        .accessibilityLabel(accessibilityLabel ?? text ?? "")
    }
    
    private var backgroundMaterial: some ShapeStyle {
        switch style {
        case .digit:
            // Clean white/light background for digits with subtle glass effect
            return AnyShapeStyle(Material.regular)
        case .increment:
            // Red glass effect with transparency (Plus buttons)
            return AnyShapeStyle(Color(.systemRed).opacity(0.12).blendMode(.normal))
        case .decrement:
            // Green glass effect with transparency (Minus buttons)  
            return AnyShapeStyle(Color(.systemGreen).opacity(0.12).blendMode(.normal))
        case .special:
            // Orange glass effect with transparency (Rest button)
            return AnyShapeStyle(Color(.systemOrange).opacity(0.12).blendMode(.normal))
        case .success:
            // Blue glass effect with transparency (Match button)
            return AnyShapeStyle(Color(.systemBlue).opacity(0.12).blendMode(.normal))
        case .control:
            // Slightly darker glass material for control keys
            return AnyShapeStyle(Material.thick)
        }
    }
    
    private var keyCornerRadius: CGFloat {
        // Use smaller corner radius for digit keys to match Apple keyboard
        return style == .digit ? 6 : config.cornerRadius
    }
    
    private var textColor: Color {
        switch style {
        case .digit:
            return .primary
        case .increment:
            return Color(.systemRed)
        case .decrement:
            return Color(.systemGreen)
        case .special:
            return Color(.systemOrange)
        case .success:
            return Color(.systemBlue)
        case .control:
            return .primary
        }
    }
    
    private var shadowColor: Color {
        switch style {
        case .digit, .control:
            return Color.black.opacity(0.08)
        case .increment:
            return Color(.systemRed).opacity(0.15)
        case .decrement:
            return Color(.systemGreen).opacity(0.15)
        case .special:
            return Color(.systemOrange).opacity(0.15)
        case .success:
            return Color(.systemBlue).opacity(0.15)
        }
    }
}

// MARK: - Button Style Enum
private enum KeyboardButtonStyle {
    case digit
    case increment
    case decrement
    case special
    case success
    case control
}

// MARK: - Button Press Modifier
private struct PressedModifier: ViewModifier {
    @State private var isPressed = false
    let onPressedChange: (Bool) -> Void
    
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed {
                            isPressed = true
                            onPressedChange(true)
                        }
                    }
                    .onEnded { _ in
                        isPressed = false
                        onPressedChange(false)
                    }
            )
    }
}

private extension View {
    func onPressedChange(_ action: @escaping (Bool) -> Void) -> some View {
        modifier(PressedModifier(onPressedChange: action))
    }
}

private struct ScoreTextField: UIViewRepresentable {
    @Binding var text: String
    @Binding var shouldFocus: Bool
    var isEnabled: Bool
    var onSelect: () -> Void
    var onPlus20: () -> Void
    var onPlus50: () -> Void
    var onPlus100: () -> Void
    var onMinus20: () -> Void
    var onMinus50: () -> Void
    var onMinus100: () -> Void
    var onClearBottom: () -> Void
    var onRest: () -> Void
    var onMatch: () -> Void
    var onDone: () -> Void

    func makeUIView(context: Context) -> UITextField {
        let tf = UITextField()
        tf.textAlignment = .center
        tf.font = UIFont.monospacedDigitSystemFont(ofSize: 14, weight: .regular)
        tf.borderStyle = .none
        tf.delegate = context.coordinator
        tf.addTarget(context.coordinator, action: #selector(Coordinator.textDidChange(_:)), for: .editingChanged)
        tf.inputAssistantItem.leadingBarButtonGroups = []
        tf.inputAssistantItem.trailingBarButtonGroups = []
        context.coordinator.configure(for: tf)
        tf.isUserInteractionEnabled = isEnabled
        return tf
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        if uiView.text != text { uiView.text = text }
        uiView.isUserInteractionEnabled = isEnabled
        if isEnabled && shouldFocus && !uiView.isFirstResponder {
            uiView.becomeFirstResponder()
            DispatchQueue.main.async { self.shouldFocus = false }
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: ScoreTextField
        weak var textField: UITextField?
        var hostingController: UIHostingController<CustomScoreKeyboard>?

        init(_ parent: ScoreTextField) { self.parent = parent }

        func configure(for tf: UITextField) {
            self.textField = tf
            // Combined keyboard with digits and special keys as inputView
            let keyboard = CustomScoreKeyboard(
                onDigit: { [weak self] d in self?.appendDigit(d) },
                onDelete: { [weak self] in self?.deleteDigit() },
                onPlus20: parent.onPlus20,
                onPlus50: parent.onPlus50,
                onPlus100: parent.onPlus100,
                onMinus20: parent.onMinus20,
                onMinus50: parent.onMinus50,
                onMinus100: parent.onMinus100,
                onClearBottom: parent.onClearBottom,
                onRest: parent.onRest,
                onMatch: parent.onMatch,
                onDone: { [weak self] in self?.done() }
            )
            let host = UIHostingController(rootView: keyboard)
            host.view.backgroundColor = .clear
            let inputView = UIInputView(frame: .zero, inputViewStyle: .keyboard)
            inputView.translatesAutoresizingMaskIntoConstraints = false
            host.view.translatesAutoresizingMaskIntoConstraints = false
            inputView.addSubview(host.view)
            NSLayoutConstraint.activate([
                host.view.leadingAnchor.constraint(equalTo: inputView.leadingAnchor),
                host.view.trailingAnchor.constraint(equalTo: inputView.trailingAnchor),
                host.view.topAnchor.constraint(equalTo: inputView.topAnchor),
                host.view.bottomAnchor.constraint(equalTo: inputView.bottomAnchor)
            ])
            // Height calculation for the custom keyboard
            let width = UIScreen.main.bounds.width
            let config = KeyboardConfiguration(width: width)
            let totalHeight: CGFloat = config.digitKeyHeight + (config.keyHeight * 3) + (config.spacing * 3) + (config.containerPadding * 2) + 24
            inputView.heightAnchor.constraint(equalToConstant: totalHeight).isActive = true
            tf.inputView = inputView

            self.hostingController = host
        }

        @objc func textDidChange(_ tf: UITextField) {
            parent.text = tf.text ?? ""
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            parent.onSelect()
        }

        private func appendDigit(_ d: Int) {
            guard let tf = textField else { return }
            var current = tf.text ?? ""
            if current == "0" { current = "" }
            // Limit input to 3 digits maximum
            if current.count >= 3 { return }
            current.append(String(d))
            tf.text = current
            parent.text = current
        }

        private func deleteDigit() {
            guard let tf = textField else { return }
            var current = tf.text ?? ""
            if !current.isEmpty { current.removeLast() }
            tf.text = current
            parent.text = current
        }

        private func done() {
            textField?.resignFirstResponder()
            parent.onDone()
        }
    }
}

// MARK: - Sheets
private struct NamesSheet: View {
    @ObservedObject var vm: ScoreboardViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Int?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach(0..<6, id: \.self) { index in
                        HStack(spacing: 12) {
                            // Player indicator with cleaner styling
                            Text("\(index + 1)")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(index < vm.players.count ? .white : .secondary)
                                .frame(width: 32, height: 32)
                                .background {
                                    Circle()
                                        .fill(
                                            index < vm.players.count ?
                                            AnyShapeStyle(Color.accentColor) :
                                            AnyShapeStyle(Material.ultraThin)
                                        )
                                        .shadow(
                                            color: index < vm.players.count ? 
                                                Color.accentColor.opacity(0.3) : 
                                                Color.clear,
                                            radius: 2,
                                            x: 0,
                                            y: 1
                                        )
                                }
                            
                            // Text field with enhanced styling
                            TextField("Spieler \(index + 1)", text: Binding(
                                get: { vm.allNames.indices.contains(index) ? vm.allNames[index] : "Spieler \(index + 1)" },
                                set: { newValue in
                                    // Ensure allNames array has enough capacity
                                    while vm.allNames.count <= index {
                                        vm.allNames.append("Spieler \(vm.allNames.count + 1)")
                                    }
                                    let trimmedValue = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                                    vm.allNames[index] = trimmedValue.isEmpty ? "Spieler \(index + 1)" : trimmedValue
                                    vm.setName(vm.allNames[index], for: index)
                                }
                            ))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .focused($focusedField, equals: index)
                            .submitLabel(.next)
                            .onSubmit {
                                // Move to next field or dismiss keyboard
                                if index < 5 {
                                    focusedField = index + 1
                                } else {
                                    focusedField = nil
                                }
                            }
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.words)
                        }
                        .padding(.vertical, 4)
                    }
                } footer: {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(.secondary)
                        Text("\(vm.players.count) von 6 Spielern aktiv")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Namen bearbeiten")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .topBarLeading) {
                    Button("Abbrechen") {
                        focusedField = nil
                        dismiss()
                    }
                }
                
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button("Fertig") {
                        // Apply default names for empty fields before closing
                        for index in 0..<6 {
                            if vm.allNames.indices.contains(index) {
                                let trimmed = vm.allNames[index].trimmingCharacters(in: .whitespacesAndNewlines)
                                if trimmed.isEmpty {
                                    vm.allNames[index] = "Spieler \(index + 1)"
                                    vm.setName(vm.allNames[index], for: index)
                                }
                            }
                        }
                        focusedField = nil
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
                
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    
                    Button("Fertig") {
                        focusedField = nil
                    }
                    .fontWeight(.medium)
                }
            }
            .onAppear {
                // Ensure allNames has all 6 entries with proper defaults
                while vm.allNames.count < 6 {
                    vm.allNames.append("Spieler \(vm.allNames.count + 1)")
                }
                // Ensure existing entries have proper defaults if empty
                for index in 0..<6 {
                    if vm.allNames[index].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        vm.allNames[index] = "Spieler \(index + 1)"
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(focusedField != nil)
    }
}

private struct PlayerCountSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var count: Int
    let onConfirm: (Int) -> Void

    init(count: Int, onConfirm: @escaping (Int) -> Void) {
        _count = State(initialValue: count)
        self.onConfirm = onConfirm
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Spieleranzahl").font(.title2.weight(.semibold))
            Picker("Spieler", selection: $count) {
                ForEach(3...6, id: \.self) { Text("\($0)").tag($0) }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            Button("OK") { onConfirm(count); dismiss() }
                .buttonStyle(.borderedProminent)
        }
        .padding()
        .presentationDetents([.height(180)])
    }
}

// MARK: - Preview
#Preview { ContentView() }

