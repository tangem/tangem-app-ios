//
//  HoldToConfirmButtonModel.swift
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
final class HoldToConfirmButtonModel: ObservableObject {
    typealias Configuration = HoldToConfirmButton.Configuration

    @Published private(set) var state: State = .idle
    @Published private(set) var confirmTrigger: UInt = 0
    @Published private(set) var shakeTrigger: CGFloat = 0

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

    private let configuration: Configuration

    private var countUpSubscription: AnyCancellable?
    private var touchesSubscription: AnyCancellable?

    init(configuration: Configuration) {
        self.configuration = configuration
        setup()
    }
}

// MARK: - Internal methods

extension HoldToConfirmButtonModel {
    func onTouches(view: UIView?, touches: Set<UITouch>, event: UIEvent?) {
        guard shouldObserveTouches() else { return }
        bindTouchesIfNeeded()

        let item = TouchesItem(view: view, touches: touches, event: event)
        touchesSubject.send(item)
    }

    func labelText(title: String) -> String {
        switch state {
        case .idle, .holding, .confirmed, .loading, .disabled: title
        case .canceled: configuration.cancelTitle
        }
    }

    func onLoading(_ isLoading: Bool) {
        if isLoading {
            startLoading()
        } else {
            stopLoading()
        }
    }

    func onEnabled(_ isEnabled: Bool) {
        if isEnabled {
            enable()
        } else {
            disable()
        }
    }
}

// MARK: - Private methods

private extension HoldToConfirmButtonModel {
    func setup() {
        holdingGenerator.prepare()
        shakingGenerator.prepare()
        loadingGenerator.prepare()
    }
}

// MARK: - Touches

private extension HoldToConfirmButtonModel {
    func shouldObserveTouches() -> Bool {
        [.idle, .holding, .canceled].contains(state)
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

private extension HoldToConfirmButtonModel {
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
        state = .confirmed
        unbindTouches()
        confirmTrigger += 1
    }

    func startLoading() {
        setup(state: .loading)
        singleVibration(generator: loadingGenerator)
    }

    func stopLoading() {
        setup(state: .idle)
    }

    func enable() {
        setup(state: .idle)
    }

    func disable() {
        setup(state: .disabled)
        unbindTouches()
    }

    func setup(state: State) {
        self.state = state
    }
}

// MARK: - Impacts

private extension HoldToConfirmButtonModel {
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

extension HoldToConfirmButtonModel {
    enum State {
        case idle
        case holding
        case canceled
        case confirmed
        case loading
        case disabled
    }

    struct TouchesItem {
        let view: UIView?
        let touches: Set<UITouch>?
        let event: UIEvent?
    }
}
