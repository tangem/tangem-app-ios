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

    private var initialHeight: CGFloat?

    private let scrollViewInteractor: RefreshScrollViewInteractor
    private var bag: Set<AnyCancellable> = []

    public init(scrollViewInteractor: RefreshScrollViewInteractor) {
        self.scrollViewInteractor = scrollViewInteractor
        heightRatioPublisher = heightRatioSubject.eraseToAnyPublisher()
        bind()
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
                case .collapsing(let item):
                    return item.heightRatio
                case .expanding(let item):
                    return item.heightRatio
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
            let item = CollapsingItem(heightRatio: heightRatio)
            return .collapsing(item)
        case .collapsed, .expanding:
            let item = ExpandingItem(heightRatio: heightRatio)
            return .expanding(item)
        }
    }

    // Scroll: idle state
    func reduce(state: State) -> State {
        let targetState: State

        switch state {
        case .collapsing(let item):
            let collapseRatio = 1 - item.heightRatio
            targetState = collapseRatio > collapseThreshold ? .collapsed : .expanded
        case .expanding(let item):
            let expandRatio = item.heightRatio
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
            // Scroll back to the initial position
            let offset = CGPoint(x: 0, y: initialScrollOffset)
            scrollViewInteractor.setContentOffset(offset, animated: true)
        case .collapsed:
            // Scroll down by the container's height to hide it
            let offset = CGPoint(x: 0, y: initialHeight + initialScrollOffset)
            scrollViewInteractor.setContentOffset(offset, animated: true)
        case .collapsing, .expanding:
            break
        }
    }

    func clamped(heightRatio: CGFloat) -> CGFloat {
        clamp(heightRatio, min: 0, max: 1)
    }
}

private extension TangemElasticContainerModel {
    enum ScrollState {
        case idle
        case scrolling(offset: CGFloat)
    }

    enum State: Equatable {
        case expanded
        case collapsing(CollapsingItem)
        case collapsed
        case expanding(ExpandingItem)
    }

    struct CollapsingItem: Equatable {
        let heightRatio: CGFloat
    }

    struct ExpandingItem: Equatable {
        let heightRatio: CGFloat
    }
}
