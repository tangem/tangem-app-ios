//
//  ButtonHoldModel.swift
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
final class ButtonHoldModel: ObservableObject {
    typealias Configuration = Button.HoldConfiguration

    @Published private(set) var state: State
    @Published private(set) var isDisabled: Bool

    @Published private(set) var shakeTrigger: CGFloat = 0
    @Published private(set) var isPulsing = false

    var showsCancelHint: Bool {
        state == .canceled
    }

    var isFilled: Bool {
        [.holding, .confirmed].contains(state)
    }

    var isCompleted: Bool {
        [.confirmed, .loading].contains(state)
    }

    var acceptsTouches: Bool {
        shouldObserveTouches()
    }

    var holdDuration: TimeInterval {
        configuration.holdDuration
    }

    var shakeDuration: TimeInterval {
        configuration.shakeDuration
    }

    private let touchesSubject = PassthroughSubject<TouchesItem, Never>()

    private let loadingGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let holdGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let notificationGenerator = UINotificationFeedbackGenerator()

    @Published private var configuration: Configuration
    private var action: () -> Void

    private var pendingSubscription: AnyCancellable?
    private var pulseSubscription: AnyCancellable?
    private var touchesSubscription: AnyCancellable?
    private var isConfirmationPending = false

    init(
        isLoading: Bool,
        isDisabled: Bool,
        configuration: Configuration,
        action: @escaping () -> Void
    ) {
        state = isLoading ? .loading : .idle
        self.isDisabled = isDisabled
        self.configuration = configuration
        self.action = action
        setup()
    }
}

// MARK: - Internal methods

extension ButtonHoldModel {
    func onTouches(view: UIView?, touches: Set<UITouch>, event: UIEvent?) {
        guard shouldObserveTouches() else { return }
        bindTouchesIfNeeded()

        let item = TouchesItem(view: view, touches: touches, event: event)
        touchesSubject.send(item)
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

    func onActionChanged(action: @escaping () -> Void) {
        self.action = action
    }
}

// MARK: - Private methods

private extension ButtonHoldModel {
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

private extension ButtonHoldModel {
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

private extension ButtonHoldModel {
    func startHolding() {
        setup(state: .holding)
        pulse()
        vibrate(
            curve: makeHoldAccelerationCurve(),
            onComplete: { [weak self] in
                self?.confirm()
            }
        )
    }

    /// Builds the acceleration curve for the current hold, using the configured hold duration
    /// so the haptic timing always matches the visual progress bar.
    func makeHoldAccelerationCurve() -> Constants.HoldAccelerationCurve {
        Constants.HoldAccelerationCurve(
            startFrequency: Constants.holdStartFrequency,
            endFrequency: Constants.holdEndFrequency,
            totalDuration: configuration.holdDuration
        )
    }

    func cancelHolding() {
        setup(state: .canceled)
        shake()
        pendingSubscription = Just(())
            .delay(for: Constants.cancelDelay, scheduler: DispatchQueue.main)
            .handleEvents(receiveOutput: { [weak self] _ in self?.notificationGenerator.notificationOccurred(.error) })
            .delay(for: Constants.cancelHintDuration, scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.setup(state: .idle)
            }
    }

    func confirm() {
        setup(state: .confirmed)
        unbindTouches()
        isConfirmationPending = true
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
                isConfirmationPending = false
                action()
                awaitLoading()
            }
    }

    func awaitLoading() {
        pendingSubscription = Just(())
            .delay(for: Constants.loadingGracePeriod, scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self, state == .confirmed else { return }
                setup(state: .idle)
            }
    }

    func startLoading() {
        let isLoadingAfterAction = state == .confirmed && !isConfirmationPending

        dropUnconfirmedHold()
        setup(state: .loading)

        if isLoadingAfterAction {
            singleVibration(generator: loadingGenerator)
        }
    }

    func stopLoading() {
        setup(state: isConfirmationPending ? .confirmed : .idle)
    }

    func enable() {
        isDisabled = false

        guard state != .loading, !isConfirmationPending else { return }

        setup(state: .idle)
    }

    func disable() {
        isDisabled = true
        dropUnconfirmedHold()
    }

    func dropUnconfirmedHold() {
        unbindTouches()

        guard [.holding, .canceled].contains(state) else { return }

        pendingSubscription = nil
        setup(state: .idle)
    }

    func setup(state: State) {
        self.state = state
    }
}

// MARK: - Impacts

private extension ButtonHoldModel {
    func vibrate(
        curve: Constants.HoldAccelerationCurve,
        onComplete: @escaping () -> Void
    ) {
        // First hit immediately so the touch feels responsive.
        singleVibration(generator: holdGenerator)

        let timestamps = makeAcceleratedTimestamps(curve: curve).filter { $0 < curve.totalDuration }
        // `true` = vibrate, `false` = end marker so MergeMany completes at totalDuration
        // even when the last hit lands slightly earlier than totalDuration.
        let hitPublishers = timestamps.map { timestamp in
            Just(true).delay(for: .seconds(timestamp), scheduler: DispatchQueue.main).eraseToAnyPublisher()
        }
        let endMarker = Just(false)
            .delay(for: .seconds(curve.totalDuration), scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()

        pendingSubscription = Publishers.MergeMany(hitPublishers + [endMarker])
            .sink(
                receiveCompletion: { _ in
                    onComplete()
                },
                receiveValue: { [weak self] shouldVibrate in
                    guard let self, shouldVibrate else { return }
                    singleVibration(generator: holdGenerator)
                }
            )
    }

    /// Computes absolute timestamps for individual hits.
    /// Interval shrinks along an ease-out curve `1 - (1-t)²` from `1/startFrequency`
    /// to `1/endFrequency` — initial intervals drop quickly after a brief slow start,
    /// then keep shrinking gently towards the end. Produces more hits than linear/quadratic.
    func makeAcceleratedTimestamps(curve: Constants.HoldAccelerationCurve) -> [TimeInterval] {
        let startInterval = 1.0 / max(0.001, curve.startFrequency)
        let endInterval = 1.0 / max(0.001, curve.endFrequency)
        // Mean of `start + (1 - (1-t)²) · (end - start)` over t ∈ [0,1] is `(start + 2·end)/3`.
        let avgInterval = (startInterval + 2 * endInterval) / 3
        let count = max(1, Int((curve.totalDuration / avgInterval).rounded()))

        var timestamps: [TimeInterval] = []
        timestamps.reserveCapacity(count)
        var cumulative: TimeInterval = 0
        for i in 1 ... count {
            let t: Double = count == 1 ? 0 : Double(i - 1) / Double(count - 1)
            let easeOut = 1 - (1 - t) * (1 - t)
            let interval = startInterval + easeOut * (endInterval - startInterval)
            cumulative += interval
            timestamps.append(cumulative)
        }
        return timestamps
    }

    func singleVibration(generator: UIImpactFeedbackGenerator) {
        generator.impactOccurred()
    }

    func shake() {
        shakeTrigger += 1
    }

    func pulse() {
        isPulsing = true
        pulseSubscription = Just(())
            .delay(for: .seconds(Button.HoldMotion.pulseHalfDuration), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.isPulsing = false
            }
    }
}

// MARK: - Types

extension ButtonHoldModel {
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

extension ButtonHoldModel {
    enum Constants {
        /// Acceleration of hit frequency over a fixed duration.
        /// Intervals shrink along an ease-out curve from `1/startFrequency` to `1/endFrequency`.
        /// Number of hits is derived automatically.
        struct HoldAccelerationCurve {
            let startFrequency: Double // Hz at t=0
            let endFrequency: Double // Hz at t=totalDuration
            let totalDuration: TimeInterval
        }

        /// Hit frequency at the start of the hold (slow, distinct ticks).
        static let holdStartFrequency: Double = 3
        /// Hit frequency at the end of the hold (rapid finale).
        /// Ease-out curve drops intervals quickly after a brief slow start, so the acceleration
        /// is felt early and keeps building — similar to iOS Clock timer feedback.
        static let holdEndFrequency: Double = 20
        static let cancelDelay: DispatchQueue.SchedulerTimeType.Stride = .seconds(0.2)
        static let cancelHintDuration: DispatchQueue.SchedulerTimeType.Stride = .seconds(0.8)
        static let confirmDelay: DispatchQueue.SchedulerTimeType.Stride = .seconds(0.4)
        static let confirmHitInterval: DispatchQueue.SchedulerTimeType.Stride = .seconds(0.1)
        static let loadingGracePeriod: DispatchQueue.SchedulerTimeType.Stride = .seconds(1)
    }
}
