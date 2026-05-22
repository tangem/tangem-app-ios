//
//  HapticPlaygroundView.swift
//  Tangem
//
//  Debug overlay to tune haptic feedback patterns.
//

import SwiftUI
import UIKit
import Combine

// MARK: - Root

struct HapticPlaygroundView: View {
    var body: some View {
        TabView {
            HapticSingleHitView()
                .tabItem { Label("Single", systemImage: "hand.tap") }

            HapticPatternEditorView()
                .tabItem { Label("Pattern", systemImage: "waveform") }
        }
    }
}

// MARK: - Single Hit playground

@MainActor
final class HapticSingleHitViewModel: ObservableObject {
    enum Generator: Equatable, Hashable {
        case impact(UIImpactFeedbackGenerator.FeedbackStyle)
        case notification(UINotificationFeedbackGenerator.FeedbackType)

        var title: String {
            switch self {
            case .impact(.light): return "Impact .light"
            case .impact(.medium): return "Impact .medium"
            case .impact(.heavy): return "Impact .heavy"
            case .impact(.soft): return "Impact .soft"
            case .impact(.rigid): return "Impact .rigid"
            case .impact: return "Impact ?"
            case .notification(.success): return "Notification .success"
            case .notification(.warning): return "Notification .warning"
            case .notification(.error): return "Notification .error"
            case .notification: return "Notification ?"
            }
        }
    }

    enum Frequency: String, CaseIterable, Identifiable {
        case slow
        case medium
        case fast

        var id: String { rawValue }

        var hz: Double {
            switch self {
            case .slow: return 2
            case .medium: return 10
            case .fast: return 30
            }
        }

        var title: String {
            switch self {
            case .slow: return "Slow (2Hz)"
            case .medium: return "Medium (10Hz)"
            case .fast: return "Fast (30Hz)"
            }
        }
    }

    @Published var active: Generator?
    @Published var frequency: Frequency = .medium {
        didSet { restartTimerIfNeeded() }
    }

    @Published var customFrequencyText: String = "" {
        didSet { restartTimerIfNeeded() }
    }

    let allGenerators: [Generator] = [
        .impact(.light),
        .impact(.medium),
        .impact(.heavy),
        .impact(.soft),
        .impact(.rigid),
        .notification(.success),
        .notification(.warning),
        .notification(.error),
    ]

    private let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let softGenerator = UIImpactFeedbackGenerator(style: .soft)
    private let rigidGenerator = UIImpactFeedbackGenerator(style: .rigid)
    private let notificationGenerator = UINotificationFeedbackGenerator()

    private var timerCancellable: AnyCancellable?

    init() {
        lightGenerator.prepare()
        mediumGenerator.prepare()
        heavyGenerator.prepare()
        softGenerator.prepare()
        rigidGenerator.prepare()
        notificationGenerator.prepare()
    }

    func toggle(_ generator: Generator) {
        if active == generator {
            stop()
        } else {
            start(generator)
        }
    }

    var effectiveHz: Double {
        let trimmed = customFrequencyText.trimmingCharacters(in: .whitespaces)
        if let custom = Double(trimmed.replacingOccurrences(of: ",", with: ".")), custom > 0 {
            return custom
        }
        return frequency.hz
    }

    private func start(_ generator: Generator) {
        active = generator
        scheduleTimer()
        fire()
    }

    private func stop() {
        active = nil
        timerCancellable = nil
    }

    private func restartTimerIfNeeded() {
        guard active != nil else { return }
        scheduleTimer()
    }

    private func scheduleTimer() {
        let hz = effectiveHz
        guard hz > 0 else {
            timerCancellable = nil
            return
        }
        let interval = 1.0 / hz
        timerCancellable = Timer
            .publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.fire()
            }
    }

    private func fire() {
        guard let active else { return }
        switch active {
        case .impact(.light): lightGenerator.impactOccurred()
        case .impact(.medium): mediumGenerator.impactOccurred()
        case .impact(.heavy): heavyGenerator.impactOccurred()
        case .impact(.soft): softGenerator.impactOccurred()
        case .impact(.rigid): rigidGenerator.impactOccurred()
        case .impact: break
        case .notification(let type): notificationGenerator.notificationOccurred(type)
        }
    }
}

struct HapticSingleHitView: View {
    @StateObject private var viewModel = HapticSingleHitViewModel()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    frequencySection
                    customFrequencySection
                    Divider()
                    generatorsSection
                    Spacer(minLength: 40)
                }
                .padding(20)
            }
            .navigationTitle("Single Hit")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var frequencySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Preset frequency")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Picker("Frequency", selection: $viewModel.frequency) {
                ForEach(HapticSingleHitViewModel.Frequency.allCases) { freq in
                    Text(freq.title).tag(freq)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var customFrequencySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Custom frequency (Hz). Overrides preset when non-empty.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack {
                TextField("e.g. 15", text: $viewModel.customFrequencyText)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                if !viewModel.customFrequencyText.isEmpty {
                    Button("Clear") {
                        viewModel.customFrequencyText = ""
                    }
                }
            }
            Text("Effective: \(String(format: "%.2f", viewModel.effectiveHz)) Hz")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var generatorsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tap to start/stop")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            ForEach(viewModel.allGenerators, id: \.self) { generator in
                Button {
                    viewModel.toggle(generator)
                } label: {
                    HStack {
                        Text(generator.title)
                            .font(.body)
                        Spacer()
                        if viewModel.active == generator {
                            Image(systemName: "stop.circle.fill")
                        } else {
                            Image(systemName: "play.circle")
                        }
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(viewModel.active == generator ? Color.accentColor.opacity(0.25) : Color.gray.opacity(0.12))
                    )
                    .foregroundStyle(viewModel.active == generator ? Color.accentColor : Color.primary)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Pattern Editor

struct HapticPatternSegment: Identifiable, Equatable {
    let id = UUID()
    var style: HapticPatternEditorViewModel.Style = .rigid
    var duration: Double // seconds
    var frequency: Double // Hz
    var intensity: Double // 0.0...1.0
}

@MainActor
final class HapticPatternEditorViewModel: ObservableObject {
    enum Style: String, CaseIterable, Identifiable {
        case light
        case medium
        case heavy
        case soft
        case rigid

        var id: String { rawValue }

        var feedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle {
            switch self {
            case .light: return .light
            case .medium: return .medium
            case .heavy: return .heavy
            case .soft: return .soft
            case .rigid: return .rigid
            }
        }

        var title: String { "." + rawValue }
    }

    /// Default style applied to newly added segments.
    @Published var defaultStyleForNewSegments: Style = .rigid

    @Published var segments: [HapticPatternSegment] = [
        // Intro: light & quiet to warm up the engine and senses without saturating them.
        HapticPatternSegment(style: .light, duration: 0.5, frequency: 10, intensity: 0.6),
        // Build: medium intensity, mid frequency.
        HapticPatternSegment(style: .medium, duration: 0.5, frequency: 20, intensity: 0.7),
        // Silence: 0 Hz produces zero events, so this segment is a 120ms pause.
        // The break lets skin receptors and the Taptic Engine reset before the finale.
        HapticPatternSegment(style: .heavy, duration: 0.12, frequency: 0, intensity: 1.0),
        // Finale: heavy style, full intensity, longer duration — punches through adaptation.
        HapticPatternSegment(style: .heavy, duration: 0.7, frequency: 40, intensity: 1.0),
    ]

    private let generators: [Style: UIImpactFeedbackGenerator] = [
        .light: UIImpactFeedbackGenerator(style: .light),
        .medium: UIImpactFeedbackGenerator(style: .medium),
        .heavy: UIImpactFeedbackGenerator(style: .heavy),
        .soft: UIImpactFeedbackGenerator(style: .soft),
        .rigid: UIImpactFeedbackGenerator(style: .rigid),
    ]

    private var playbackCancellable: AnyCancellable?

    init() {
        generators.values.forEach { $0.prepare() }
    }

    var totalDuration: Double {
        segments.reduce(0) { $0 + $1.duration }
    }

    func addSegment() {
        segments.append(HapticPatternSegment(style: defaultStyleForNewSegments, duration: 0.3, frequency: 10, intensity: 1.0))
    }

    func delete(_ segmentID: HapticPatternSegment.ID) {
        segments.removeAll { $0.id == segmentID }
    }

    func playAll() {
        let events = computeAllEvents()
        schedule(events)
    }

    func play(_ segment: HapticPatternSegment) {
        let events = computeSegmentEvents(segment, offset: 0)
        schedule(events)
    }

    func stop() {
        playbackCancellable = nil
    }

    private func computeAllEvents() -> [Event] {
        var events: [Event] = []
        var offset: Double = 0
        for segment in segments {
            events.append(contentsOf: computeSegmentEvents(segment, offset: offset))
            offset += segment.duration
        }
        return events
    }

    private func computeSegmentEvents(_ segment: HapticPatternSegment, offset: Double) -> [Event] {
        let count = Int((segment.frequency * segment.duration).rounded())
        guard count > 0, segment.duration > 0 else { return [] }
        let interval = segment.duration / Double(count)
        let clampedIntensity = max(0, min(1, segment.intensity))
        return (1 ... count).map { i in
            Event(time: offset + Double(i) * interval, intensity: clampedIntensity, style: segment.style)
        }
    }

    private func schedule(_ events: [Event]) {
        let publishers = events.map { event in
            Just(event)
                .delay(for: .seconds(event.time), scheduler: DispatchQueue.main)
                .eraseToAnyPublisher()
        }
        playbackCancellable = Publishers.MergeMany(publishers)
            .sink { [weak self] event in
                self?.generators[event.style]?.impactOccurred(intensity: CGFloat(event.intensity))
            }
    }

    private struct Event {
        let time: Double
        let intensity: Double
        let style: Style
    }
}

struct HapticPatternEditorView: View {
    @StateObject private var viewModel = HapticPatternEditorViewModel()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    styleSection
                    Divider()
                    segmentsSection
                    addButton
                    Divider()
                    playAllSection
                    Spacer(minLength: 40)
                }
                .padding(20)
            }
            .navigationTitle("Pattern Editor")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var styleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Default style for new segments")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Picker("Default style", selection: $viewModel.defaultStyleForNewSegments) {
                ForEach(HapticPatternEditorViewModel.Style.allCases) { style in
                    Text(style.title).tag(style)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var segmentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Segments")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Total: \(String(format: "%.2f", viewModel.totalDuration))s")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            ForEach(Array($viewModel.segments.enumerated()), id: \.element.id) { index, $segment in
                segmentRow(index: index + 1, segment: $segment)
            }
        }
    }

    private func segmentRow(index: Int, segment: Binding<HapticPatternSegment>) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("#\(index)")
                    .font(.headline)
                Spacer()
                let count = max(0, Int((segment.wrappedValue.frequency * segment.wrappedValue.duration).rounded()))
                Text("\(count) hits")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Picker("Style", selection: segment.style) {
                ForEach(HapticPatternEditorViewModel.Style.allCases) { style in
                    Text(style.title).tag(style)
                }
            }
            .pickerStyle(.segmented)
            HStack(spacing: 8) {
                numberField(title: "Dur (s)", value: segment.duration, format: "%.2f")
                numberField(title: "Hz", value: segment.frequency, format: "%.1f")
                numberField(title: "Intensity", value: segment.intensity, format: "%.2f")
            }
            HStack {
                Button {
                    viewModel.play(segment.wrappedValue)
                } label: {
                    Label("Play", systemImage: "play.fill")
                }
                .buttonStyle(.bordered)

                Spacer()

                Button(role: .destructive) {
                    viewModel.delete(segment.wrappedValue.id)
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.gray.opacity(0.1))
        )
    }

    private func numberField(title: String, value: Binding<Double>, format: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            TextField(title, value: value, formatter: Self.numberFormatter)
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
        }
    }

    private static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 3
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    private var addButton: some View {
        Button {
            viewModel.addSegment()
        } label: {
            Label("Add segment", systemImage: "plus.circle")
        }
        .buttonStyle(.bordered)
    }

    private var playAllSection: some View {
        HStack(spacing: 12) {
            Button {
                viewModel.playAll()
            } label: {
                Label("Play all", systemImage: "play.circle.fill")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)

            Button {
                viewModel.stop()
            } label: {
                Label("Stop", systemImage: "stop.circle")
                    .padding(.vertical, 6)
            }
            .buttonStyle(.bordered)
        }
    }
}

#if DEBUG

// MARK: - Previews

struct HapticPlaygroundView_Previews: PreviewProvider {
    static var previews: some View {
        HapticPlaygroundView()
    }
}
#endif // DEBUG
