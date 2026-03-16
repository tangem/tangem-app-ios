//
//  TangemElasticContainerModel.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import UIKit
import TangemFoundation

@MainActor
final class TangemElasticContainerModel: NSObject, ObservableObject {
    /// The current height ratio of the container (0 = collapsed, 1 = expanded)
    @Published private(set) var heightRatio: CGFloat?

    private let stateSubject = CurrentValueSubject<State, Never>(.expanded)
    private let scrollStateSubject = PassthroughSubject<ScrollState, Never>()

    private let collapseThreshold: Double = 0.3
    private let expandThreshold: Double = 0.3

    private var initialHeight: CGFloat?
    private var initialScrollOffset: CGFloat?

    private let onRemoveScrollViewObserver: (RefreshScrollViewObserver) -> Void

    private weak var scrollView: UIScrollView?
    private var bag: Set<AnyCancellable> = []

    init(
        onAddScrollViewObserver: (RefreshScrollViewObserver) -> Void,
        onRemoveScrollViewObserver: @escaping (RefreshScrollViewObserver) -> Void
    ) {
        self.onRemoveScrollViewObserver = onRemoveScrollViewObserver
        super.init()

        bind()
        onAddScrollViewObserver(self)
    }

    deinit {
        onRemoveScrollViewObserver(self)
    }
}

// MARK: - Internal methods

extension TangemElasticContainerModel {
    func onGeometry(frame: CGRect) {
        if initialHeight == nil {
            initialHeight = frame.height
        }
    }
}

// MARK: - Private methods

private extension TangemElasticContainerModel {
    func bind() {
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
            .assign(to: &$heightRatio)
    }

    // Scroll: scrolling state
    func reduce(state: State, scrollOffset: CGFloat) -> State {
        guard let initialHeight, let initialScrollOffset else {
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
        switch targetState {
        case .expanded:
            // Scroll back to the initial position
            let offset = CGPoint(x: 0, y: initialScrollOffset ?? .zero)
            scrollView?.setContentOffset(offset, animated: true)
        case .collapsed:
            // Scroll down by the container's height to hide it
            let offset = CGPoint(x: 0, y: (initialHeight ?? .zero) + (initialScrollOffset ?? .zero))
            scrollView?.setContentOffset(offset, animated: true)
        case .collapsing, .expanding:
            break
        }
    }

    func clamped(heightRatio: CGFloat) -> CGFloat {
        clamp(heightRatio, min: 0, max: 1)
    }
}

// MARK: - RefreshScrollViewObserver

extension TangemElasticContainerModel: RefreshScrollViewObserver {
    func scrollViewDidSet(_ scrollView: UIScrollView?) {
        self.scrollView = scrollView
        initialScrollOffset = scrollView?.contentOffset.y
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset = scrollView.contentOffset.y
        scrollStateSubject.send(.scrolling(offset: offset))
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard !decelerate else { return }
        scrollStateSubject.send(.idle)
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        scrollStateSubject.send(.idle)
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
