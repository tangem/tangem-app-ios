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
        configuration.holdDuration
    }

    var shakeDuration: TimeInterval {
        configuration.shakeDuration
    }

    private let touchesSubject = PassthroughSubject<TouchesItem, Never>()

    private let loadingGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let holdGenerator = UIImpactFeedbackGenerator(style: .rigid)
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
        loadingGenerator.prepare()
        holdGenerator.prepare()
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
            duration: holdDuration,
            generator: holdGenerator,
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
                singleVibration(generator: loadingGenerator)
            })
            .delay(for: Constants.confirmHitInterval, scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                singleVibration(generator: loadingGenerator)
                action()
            }
    }

    func startLoading() {
        setup(state: .loading)
        singleVibration(generator: loadingGenerator)
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
        duration: TimeInterval,
        generator: UIImpactFeedbackGenerator,
        onComplete: @escaping () -> Void
    ) {
        // Each segment fires `count` vibrations evenly over `fraction * duration`.
        // Frequency grows step-wise: few hits at start, many at the end.
        // One hit immediately so the touch feels responsive.
        singleVibration(generator: generator)
        let timestamps = makeVibrationTimestamps(duration: duration, schedule: Constants.holdVibrationSchedule)

        let publishers = timestamps.map { timestamp in
            Just(()).delay(for: .seconds(timestamp), scheduler: DispatchQueue.main).eraseToAnyPublisher()
        }

        pendingSubscription = Publishers.MergeMany(publishers)
            .sink(
                receiveCompletion: { _ in
                    onComplete()
                },
                receiveValue: { [weak self] _ in
                    self?.singleVibration(generator: generator)
                }
            )
    }

    func makeVibrationTimestamps(duration: TimeInterval, schedule: [Constants.VibrationSegment]) -> [TimeInterval] {
        var timestamps: [TimeInterval] = []
        var offset: TimeInterval = 0
        for segment in schedule {
            let segmentDuration = duration * segment.fraction
            if !segment.isEmpty {
                let interval = segmentDuration / Double(segment.count)
                for i in 1 ... segment.count {
                    timestamps.append(offset + Double(i) * interval)
                }
            }
            offset += segmentDuration
        }
        return timestamps
    }

    func singleVibration(generator: UIImpactFeedbackGenerator) {
        generator.impactOccurred()
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
}

// MARK: - Constants

extension WrappedHoldToConfirmButtonModel {
    enum Constants {
        struct VibrationSegment {
            let count: Int
            let fraction: Double

            var isEmpty: Bool { count == 0 }
        }

        /// Vibration schedule for the hold gesture. Fractions must sum to 1.0.
        /// With holdDuration = 3.0s and rigid generator: 2Hz → 4Hz → 6Hz → 10Hz → 14Hz → 20Hz.
        /// Each segment is 0.5s.
        static let holdVibrationSchedule: [VibrationSegment] = [
            VibrationSegment(count: 1, fraction: 1.0 / 6.0),
            VibrationSegment(count: 2, fraction: 1.0 / 6.0),
            VibrationSegment(count: 3, fraction: 1.0 / 6.0),
            VibrationSegment(count: 5, fraction: 1.0 / 6.0),
            VibrationSegment(count: 7, fraction: 1.0 / 6.0),
            VibrationSegment(count: 10, fraction: 1.0 / 6.0),
        ]
        static let cancelDelay: DispatchQueue.SchedulerTimeType.Stride = .seconds(0.2)
        static let confirmDelay: DispatchQueue.SchedulerTimeType.Stride = .seconds(0.4)
        static let confirmHitInterval: DispatchQueue.SchedulerTimeType.Stride = .seconds(0.1)
    }
}
