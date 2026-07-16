//
//  TangemElasticContainerModel.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

@MainActor
public final class TangemElasticContainerModel: ObservableObject {
    /// The current height ratio of the container (0 = collapsed, 1 = expanded)
    public let heightRatioPublisher: AnyPublisher<CGFloat, Never>

    private let stateSubject = CurrentValueSubject<State, Never>(.expanded)
    private let scrollStateSubject = PassthroughSubject<ScrollState, Never>()
    private let heightRatioSubject = PassthroughSubject<CGFloat, Never>()

    private let collapseThreshold: Double = 0.3
    private let expandThreshold: Double = 0.3
    /// Points-per-millisecond. Above this we snap in the flick direction via natural decel;
    /// below it we suppress decel and snap by proximity in the `.idle` reducer.
    private let snapVelocityThreshold: CGFloat = 0.1

    private var initialHeight: CGFloat?

    private let scrollViewInteractor: RefreshScrollViewInteractor
    private var bag: Set<AnyCancellable> = []

    public init(scrollViewInteractor: RefreshScrollViewInteractor) {
        self.scrollViewInteractor = scrollViewInteractor
        heightRatioPublisher = heightRatioSubject.eraseToAnyPublisher()
        bind()
        scrollViewInteractor.targetContentOffsetProvider = { [weak self] proposed, velocity in
            self?.snapTarget(proposed: proposed, velocity: velocity)
        }
    }
}

// MARK: - Internal methods

extension TangemElasticContainerModel {
    func onGeometry(frame: CGRect) {
        initialHeight = frame.height
    }
}

// MARK: - Private methods

private extension TangemElasticContainerModel {
    func bind() {
        scrollViewInteractor.eventPublisher
            .receiveOnMain()
            .compactMap { event in
                switch event {
                case .didScroll(let offset):
                    return .scrolling(offset: offset.y)
                case .didEndDragging(let willDecelerate):
                    if willDecelerate {
                        return nil
                    } else {
                        return .idle
                    }
                case .didEndDecelerating:
                    return .idle
                default:
                    return nil
                }
            }
            .subscribe(scrollStateSubject)
            .store(in: &bag)

        scrollStateSubject
            .receiveOnMain()
            .scan(stateSubject.value) { [weak self] state, scrollState in
                guard let self else { return state }
                switch scrollState {
                case .scrolling(let offset):
                    return reduce(state: state, scrollOffset: offset)
                case .idle:
                    return reduce(state: state)
                }
            }
            .removeDuplicates()
            .subscribe(stateSubject)
            .store(in: &bag)

        stateSubject
            .receiveOnMain()
            .map { state in
                switch state {
                case .collapsed:
                    return 0
                case .expanded:
                    return 1
                case .collapsing(let heightRatio), .expanding(let heightRatio):
                    return heightRatio
                }
            }
            .removeDuplicates()
            .subscribe(heightRatioSubject)
            .store(in: &bag)
    }

    // Scroll: scrolling state
    func reduce(state: State, scrollOffset: CGFloat) -> State {
        guard
            let initialHeight,
            let initialScrollOffset = scrollViewInteractor.initialScrollOffset?.y
        else {
            return state
        }

        // Calculate how much the user has scrolled from the initial position
        let offset = scrollOffset - initialScrollOffset

        let offsetRatio = initialHeight > 0 ? offset / initialHeight : 0
        let heightRatio = clamped(heightRatio: 1 - offsetRatio)

        if heightRatio >= 1 {
            return .expanded
        } else if heightRatio <= 0 {
            return .collapsed
        }

        switch state {
        case .expanded, .collapsing:
            return .collapsing(heightRatio: heightRatio)
        case .collapsed, .expanding:
            return .expanding(heightRatio: heightRatio)
        }
    }

    // Scroll: idle state
    func reduce(state: State) -> State {
        let targetState: State

        switch state {
        case .collapsing(let heightRatio):
            let collapseRatio = 1 - heightRatio
            targetState = collapseRatio > collapseThreshold ? .collapsed : .expanded
        case .expanding(let heightRatio):
            let expandRatio = heightRatio
            targetState = expandRatio > expandThreshold ? .expanded : .collapsed
        case .expanded, .collapsed:
            targetState = state
        }

        if targetState != state {
            scroll(to: targetState)
        }

        return targetState
    }

    func scroll(to targetState: State) {
        guard
            let initialHeight,
            let initialScrollOffset = scrollViewInteractor.initialScrollOffset?.y
        else {
            return
        }

        switch targetState {
        case .expanded:
            let offset = CGPoint(x: 0, y: initialScrollOffset)
            scrollViewInteractor.setContentOffset(offset, animated: true)
        case .collapsed:
            let offset = CGPoint(x: 0, y: clampToValidOffset(initialHeight + initialScrollOffset))
            scrollViewInteractor.setContentOffset(offset, animated: true)
        case .collapsing, .expanding:
            break
        }
    }

    func clamped(heightRatio: CGFloat) -> CGFloat {
        clamp(heightRatio, min: 0, max: 1)
    }

    func snapTarget(proposed: CGPoint, velocity: CGPoint) -> CGPoint? {
        guard
            let initialHeight,
            let initialScrollOffset = scrollViewInteractor.initialScrollOffset?.y,
            initialHeight > 0
        else {
            return nil
        }

        let expandedY = initialScrollOffset
        let collapsedY = initialScrollOffset + initialHeight

        guard proposed.y > expandedY, proposed.y < collapsedY else {
            return nil
        }

        // Low velocity: UIKit's natural decel curve from ~0 velocity over our snap distance is a slow
        // creep (~1s). Suppress decel by targeting current offset; `didEndDecelerating` then fires
        // immediately and the `.idle` reducer drives the explicit snap animation.
        guard abs(velocity.y) > snapVelocityThreshold else {
            return scrollViewInteractor.currentScrollOffset ?? proposed
        }

        // Flick: redirect natural decel to clamped snap point. UIScrollView silently clamps targets
        // past `contentSize - frameSize`, so we clamp ourselves to avoid bounce-back from overshoot.
        let snapY = clampToValidOffset(velocity.y > 0 ? collapsedY : expandedY)
        return CGPoint(x: proposed.x, y: snapY)
    }

    func clampToValidOffset(_ y: CGFloat) -> CGFloat {
        guard
            let frameSize = scrollViewInteractor.frameSize,
            let contentSize = scrollViewInteractor.contentSize,
            let initialScrollOffset = scrollViewInteractor.initialScrollOffset?.y
        else {
            return y
        }

        let maxY = max(initialScrollOffset, contentSize.height - frameSize.height)
        return min(y, maxY)
    }
}

private extension TangemElasticContainerModel {
    enum ScrollState {
        case idle
        case scrolling(offset: CGFloat)
    }

    enum State: Equatable {
        case expanded
        case collapsing(heightRatio: CGFloat)
        case collapsed
        case expanding(heightRatio: CGFloat)
    }
}
