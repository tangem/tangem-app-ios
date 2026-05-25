//
//  WrappedHoldToConfirmButtonModel.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import Combine
import UIKit

@MainActor
final class WrappedHoldToConfirmButtonModel: ObservableObject {
    typealias Configuration = HoldToConfirmButton.Configuration

    @Published private(set) var state: State
    @Published private(set) var isDisabled: Bool

    @Published private(set) var shakeTrigger: CGFloat = 0

    var labelTitle: String {
        switch state {
        case .idle, .holding, .confirmed, .loading: title
        case .canceled: configuration.cancelTitle
        }
    }

    var holdDuration: TimeInterval {
        Constants.holdVibrationSchedule.reduce(0.0) { $0 + $1.duration }
    }

    var shakeDuration: TimeInterval {
        configuration.shakeDuration
    }

    private let touchesSubject = PassthroughSubject<TouchesItem, Never>()

    private let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let notificationGenerator = UINotificationFeedbackGenerator()

    @Published private var title: String
    @Published private var configuration: Configuration
    private var action: () -> Void

    private var pendingSubscription: AnyCancellable?
    private var touchesSubscription: AnyCancellable?

    init(
        title: String,
        isLoading: Bool,
        isDisabled: Bool,
        configuration: Configuration,
        action: @escaping () -> Void
    ) {
        state = isLoading ? .loading : .idle
        self.title = title
        self.isDisabled = isDisabled
        self.configuration = configuration
        self.action = action
        setup()
    }
}

// MARK: - Internal methods

extension WrappedHoldToConfirmButtonModel {
    func onTouches(view: UIView?, touches: Set<UITouch>, event: UIEvent?) {
        guard shouldObserveTouches() else { return }
        bindTouchesIfNeeded()

        let item = TouchesItem(view: view, touches: touches, event: event)
        touchesSubject.send(item)
    }

    func onTitleChanged(title: String) {
        self.title = title
    }

    func onLoadingChanged(isLoading: Bool) {
        if isLoading {
            startLoading()
        } else {
            stopLoading()
        }
    }

    func onDisabledChanged(isDisabled: Bool) {
        if isDisabled {
            disable()
        } else {
            enable()
        }
    }

    func onConfigurationChanged(configuration: Configuration) {
        self.configuration = configuration
    }

    func onActionChanged(action: HoldToConfirmButton.Action) {
        self.action = action.closure
    }
}

// MARK: - Private methods

private extension WrappedHoldToConfirmButtonModel {
    func setup() {
        lightGenerator.prepare()
        mediumGenerator.prepare()
        heavyGenerator.prepare()
        notificationGenerator.prepare()

        if state == .loading {
            startLoading()
        }
    }
}

// MARK: - Touches

private extension WrappedHoldToConfirmButtonModel {
    func shouldObserveTouches() -> Bool {
        !isDisabled && [.idle, .holding, .canceled].contains(state)
    }

    func bindTouchesIfNeeded() {
        guard touchesSubscription == nil else { return }

        touchesSubscription = touchesSubject
            .map { item in
                guard let view = item.view, let eventTouches = item.event?.allTouches else {
                    return false
                }

                let activeTouches = eventTouches
                    .filter { $0.view == view && $0.phase != .ended && $0.phase != .cancelled }
                    .filter {
                        let point = $0.location(in: view)
                        return view.bounds.contains(point)
                    }

                return activeTouches.isNotEmpty
            }
            .removeDuplicates()
            .sink { [weak self] hasActiveTouches in
                if hasActiveTouches {
                    self?.startHolding()
                } else {
                    self?.cancelHolding()
                }
            }
    }

    func unbindTouches() {
        touchesSubscription = nil
    }
}

// MARK: - States

private extension WrappedHoldToConfirmButtonModel {
    func startHolding() {
        setup(state: .holding)
        vibrate(
            schedule: Constants.holdVibrationSchedule,
            onComplete: { [weak self] in
                self?.confirm()
            }
        )
    }

    func cancelHolding() {
        setup(state: .canceled)
        shake()
        pendingSubscription = Just(())
            .delay(for: Constants.cancelDelay, scheduler: DispatchQueue.main)
            .handleEvents(receiveOutput: { [weak self] _ in self?.notificationGenerator.notificationOccurred(.error) })
            .delay(for: .seconds(shakeDuration), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.setup(state: .idle)
            }
    }

    func confirm() {
        setup(state: .confirmed)
        unbindTouches()
        pendingSubscription = Just(())
            .delay(for: Constants.confirmDelay, scheduler: DispatchQueue.main)
            .handleEvents(receiveOutput: { [weak self] _ in
                guard let self else { return }
                singleVibration(generator: heavyGenerator)
            })
            .delay(for: Constants.confirmHitInterval, scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                singleVibration(generator: heavyGenerator)
                action()
            }
    }

    func startLoading() {
        setup(state: .loading)
        singleVibration(generator: heavyGenerator)
    }

    func stopLoading() {
        setup(state: .idle)
    }

    func enable() {
        isDisabled = false
        setup(state: .idle)
    }

    func disable() {
        isDisabled = true
        unbindTouches()
    }

    func setup(state: State) {
        self.state = state
    }
}

// MARK: - Impacts

private extension WrappedHoldToConfirmButtonModel {
    func vibrate(
        schedule: [Constants.VibrationSegment],
        onComplete: @escaping () -> Void
    ) {
        // Fire the first event immediately so the touch feels responsive.
        if let first = schedule.first(where: { !$0.isEmpty }) {
            singleVibration(generator: generator(for: first.style), intensity: CGFloat(first.intensity))
        }

        let events = makeVibrationEvents(schedule: schedule)
        let totalDuration = schedule.reduce(0.0) { $0 + $1.duration }

        // Each event becomes a Just publisher delayed to its absolute timestamp.
        // A final no-op event at totalDuration guarantees MergeMany completes at the right time,
        // even when the schedule ends with a silence segment.
        let eventPublishers = events.map { event in
            Just<VibrationEvent?>(event)
                .delay(for: .seconds(event.time), scheduler: DispatchQueue.main)
                .eraseToAnyPublisher()
        }
        let endMarker = Just<VibrationEvent?>(nil)
            .delay(for: .seconds(totalDuration), scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()

        pendingSubscription = Publishers.MergeMany(eventPublishers + [endMarker])
            .sink(
                receiveCompletion: { _ in
                    onComplete()
                },
                receiveValue: { [weak self] event in
                    guard let self, let event else { return }
                    singleVibration(generator: generator(for: event.style), intensity: CGFloat(event.intensity))
                }
            )
    }

    func makeVibrationEvents(schedule: [Constants.VibrationSegment]) -> [VibrationEvent] {
        var events: [VibrationEvent] = []
        var offset: TimeInterval = 0
        for segment in schedule {
            if !segment.isEmpty {
                let interval = segment.duration / Double(segment.count)
                for i in 1 ... segment.count {
                    events.append(VibrationEvent(
                        time: offset + Double(i) * interval,
                        style: segment.style,
                        intensity: segment.intensity
                    ))
                }
            }
            offset += segment.duration
        }
        return events
    }

    func generator(for style: UIImpactFeedbackGenerator.FeedbackStyle) -> UIImpactFeedbackGenerator {
        switch style {
        case .light: return lightGenerator
        case .medium: return mediumGenerator
        case .heavy: return heavyGenerator
        case .soft, .rigid: return mediumGenerator
        @unknown default: return mediumGenerator
        }
    }

    func singleVibration(generator: UIImpactFeedbackGenerator, intensity: CGFloat = 1.0) {
        generator.impactOccurred(intensity: intensity)
    }

    func shake() {
        shakeTrigger += 1
    }
}

// MARK: - Types

extension WrappedHoldToConfirmButtonModel {
    enum State {
        case idle
        case holding
        case canceled
        case confirmed
        case loading
    }

    struct TouchesItem {
        let view: UIView?
        let touches: Set<UITouch>?
        let event: UIEvent?
    }

    struct VibrationEvent {
        let time: TimeInterval
        let style: UIImpactFeedbackGenerator.FeedbackStyle
        let intensity: Double
    }
}

// MARK: - Constants

extension WrappedHoldToConfirmButtonModel {
    enum Constants {
        struct VibrationSegment {
            let style: UIImpactFeedbackGenerator.FeedbackStyle
            let duration: TimeInterval
            let frequency: Double
            let intensity: Double

            var count: Int { max(0, Int((frequency * duration).rounded())) }
            var isEmpty: Bool { count == 0 }
        }

        /// Vibration schedule for the hold gesture. Sum of segment durations defines total hold time.
        /// Pattern: light 5Hz → medium 10Hz → silence 100ms → heavy 20Hz → heavy 30Hz.
        /// Silence segment resets sensory adaptation before the strong finale.
        static let holdVibrationSchedule: [VibrationSegment] = [
            VibrationSegment(style: .light, duration: 0.5, frequency: 2, intensity: 1.0),
            VibrationSegment(style: .medium, duration: 0.5, frequency: 5, intensity: 1.0),
            VibrationSegment(style: .heavy, duration: 0.1, frequency: 0, intensity: 1.0),
            VibrationSegment(style: .heavy, duration: 0.5, frequency: 10, intensity: 1.0),
            VibrationSegment(style: .heavy, duration: 0.5, frequency: 20, intensity: 1.0),
        ]
        static let cancelDelay: DispatchQueue.SchedulerTimeType.Stride = .seconds(0.2)
        static let confirmDelay: DispatchQueue.SchedulerTimeType.Stride = .seconds(0.4)
        static let confirmHitInterval: DispatchQueue.SchedulerTimeType.Stride = .seconds(0.1)
    }
}
