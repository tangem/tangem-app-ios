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

    private let holdingGenerator = UIImpactFeedbackGenerator(style: .light)
    private let shakingGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let loadingGenerator = UIImpactFeedbackGenerator(style: .heavy)

    @Published private var title: String
    @Published private var configuration: Configuration
    private var action: () -> Void

    private var countUpSubscription: AnyCancellable?
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
        holdingGenerator.prepare()
        shakingGenerator.prepare()
        loadingGenerator.prepare()

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
            generator: holdingGenerator,
            onComplete: { [weak self] in
                self?.confirm()
            }
        )
    }

    func cancelHolding() {
        setup(state: .canceled)
        shake()
        vibrate(
            duration: shakeDuration,
            generator: shakingGenerator,
            onComplete: { [weak self] in
                self?.setup(state: .idle)
            }
        )
    }

    func confirm() {
        setup(state: .confirmed)
        unbindTouches()
        action()
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
        let vibratesCount = Int(duration * TimeInterval(configuration.vibratesPerSecond))
        countUpSubscription = makeCountUpPublisher(interval: duration, count: vibratesCount)
            .sink(
                receiveCompletion: { _ in
                    onComplete()
                },
                receiveValue: { [weak self] _ in
                    self?.singleVibration(generator: generator)
                }
            )
    }

    func singleVibration(generator: UIImpactFeedbackGenerator) {
        generator.impactOccurred()
    }

    func makeCountUpPublisher(interval: TimeInterval, count: Int) -> AnyPublisher<Int, Never> {
        let tickInterval = interval / Double(count)
        return Timer
            .publish(every: tickInterval, on: .main, in: .common)
            .autoconnect()
            .scan(0) { counter, _ in
                counter + 1
            }
            .prefix(while: { $0 <= count })
            .eraseToAnyPublisher()
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
