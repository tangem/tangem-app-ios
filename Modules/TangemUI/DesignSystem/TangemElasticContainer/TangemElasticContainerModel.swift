//
//  TangemElasticContainerModel.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import UIKit
import Combine
import CombineExt

@MainActor
final class TangemElasticContainerModel: NSObject, ObservableObject {
    typealias State = TangemElasticContainerState

    @Published private(set) var state: State = .expanded

    var topPadding: CGFloat {
        switch state {
        case .collapsing(let ratio):
            return resistanceHeight(ratio: ratio)
        case .expanding(let ratio):
            return -huggingHeight(ratio: ratio)
        case .expanded, .collapsed:
            return 0
        }
    }

    var scrollToIdPublisher: AnyPublisher<AnyHashable, Never> {
        scrollToIdSubject.eraseToAnyPublisher()
    }

    let topAnchorId: AnyHashable = UUID()
    let bottomAnchorId: AnyHashable = UUID()

    private let scrollToIdSubject = PassthroughSubject<AnyHashable, Never>()
    private let scrollStateSubject = PassthroughSubject<ScrollState, Never>()
    private let scrollOffsetSubject = PassthroughSubject<CGPoint, Never>()

    private let collapseThreshold: Double = 0.5
    private let expandThreshold: Double = 0.1

    private var initialFrame: CGRect?
    private var initialScrollOffset: CGPoint?

    private let onRemoveScrollViewDelegate: (UIScrollViewDelegate) -> Void

    private var bag: Set<AnyCancellable> = []

    init(
        onAddScrollViewDelegate: (UIScrollViewDelegate) -> Void,
        onRemoveScrollViewDelegate: @escaping (UIScrollViewDelegate) -> Void
    ) {
        self.onRemoveScrollViewDelegate = onRemoveScrollViewDelegate
        super.init()

        bind()
        onAddScrollViewDelegate(self)
    }

    deinit {
        onRemoveScrollViewDelegate(self)
    }
}

// MARK: - Internal methods

extension TangemElasticContainerModel {
    func onGeometry(frame: CGRect) {
        guard initialFrame == nil else { return }
        initialFrame = frame
    }
}

// MARK: - Private methods

private extension TangemElasticContainerModel {
    func bind() {
        scrollOffsetSubject
            .receiveOnMain()
            .scan(state) { [weak self] state, scrollOffset in
                guard let self else { return state }
                return self.state(for: state, with: scrollOffset)
            }
            .removeDuplicates()
            .assign(to: &$state)

        let scrollIdleStatePublisher = scrollStateSubject
            .removeDuplicates()
            .scan((ScrollState?, ScrollState?)(nil, nil)) { previousStates, newState in
                let oldState = previousStates.1
                return (oldState, newState)
            }
            .filter { oldState, newState in
                [.dragging, .decelerating].contains(oldState) && newState == .idle
            }
            .map { _ in }

        scrollIdleStatePublisher
            .withLatestFrom($state)
            .compactMap { [weak self] state in
                guard let self else { return nil }
                return scrollToId(for: state)
            }
            .subscribe(scrollToIdSubject)
            .store(in: &bag)
    }

    func state(for state: State, with scrollOffset: CGPoint) -> State {
        guard let initialFrame, let initialScrollOffset else {
            return state
        }

        let offset = scrollOffset.y - initialScrollOffset.y

        if offset <= 0 {
            return .expanded
        }

        let initialHeight = initialFrame.height

        if offset >= initialHeight {
            return .collapsed
        }

        switch state {
        case .expanded, .collapsing:
            return collapseState(initialHeight: initialHeight, offset: offset)
        case .collapsed, .expanding:
            return expandState(initialHeight: initialHeight, offset: offset)
        }
    }

    func scrollToId(for state: State) -> AnyHashable? {
        switch state {
        case .collapsing(let ratio):
            ratio > collapseThreshold ? bottomAnchorId : topAnchorId
        case .expanding(let ratio):
            ratio > expandThreshold ? topAnchorId : bottomAnchorId
        case .expanded, .collapsed:
            nil
        }
    }
}

// MARK: - Collapse state

private extension TangemElasticContainerModel {
    func collapseState(initialHeight: CGFloat, offset: CGFloat) -> State {
        guard initialHeight > 0 else { return .collapsed }
        let resistanceHeight = resistanceHeight(height: initialHeight, offset: offset)
        let height = offset - resistanceHeight
        let ratio = height / initialHeight
        return ratio < 1 ? .collapsing(ratio: ratio) : .collapsed
    }

    func resistanceHeight(ratio: CGFloat) -> CGFloat {
        guard let initialFrame else { return 0 }
        let height = initialFrame.height
        let offset = height * ratio
        return resistanceHeight(height: height, offset: offset)
    }

    func resistanceHeight(height: CGFloat, offset: CGFloat) -> CGFloat {
        guard height > 0 else { return 0 }
        let resistance = resistanceCurve(x: offset / height)
        return resistance * height
    }

    func resistanceCurve(x: CGFloat) -> CGFloat {
        let correctionFactor = 0.25
        return pow(sin(x * .pi), 2) * correctionFactor
    }
}

// MARK: - Expand state

private extension TangemElasticContainerModel {
    func expandState(initialHeight: CGFloat, offset: CGFloat) -> State {
        guard initialHeight > 0 else { return .expanded }
        let huggingHeight = huggingHeight(height: initialHeight, offset: offset)
        let height = initialHeight - offset - huggingHeight
        let ratio = height / initialHeight
        return ratio < 1 ? .expanding(ratio: ratio) : .expanded
    }

    func huggingHeight(ratio: CGFloat) -> CGFloat {
        guard let initialFrame else { return 0 }
        let height = initialFrame.height
        let offset = height * ratio
        return huggingHeight(height: height, offset: offset)
    }

    func huggingHeight(height: CGFloat, offset: CGFloat) -> CGFloat {
        guard height > 0 else { return 0 }
        let hugging = huggingCurve(x: offset / height)
        return hugging * height
    }

    func huggingCurve(x: CGFloat) -> CGFloat {
        let correctionFactor = 0.2
        return pow(sin(x * .pi), 2) * correctionFactor
    }
}

// MARK: - UIScrollViewDelegate

extension TangemElasticContainerModel: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let scrollOffset = scrollView.contentOffset
        if initialScrollOffset == nil {
            initialScrollOffset = scrollOffset
        }
        scrollOffsetSubject.send(scrollOffset)
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        scrollStateSubject.send(.dragging)
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        scrollStateSubject.send(.idle)
    }

    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        scrollStateSubject.send(.decelerating)
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        scrollStateSubject.send(.idle)
    }
}

// MARK: - Types

private extension TangemElasticContainerModel {
    enum ScrollState {
        case idle
        case dragging
        case decelerating
    }
}
