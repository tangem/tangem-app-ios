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

    /// Dynamic top padding used to simulate resistance / hugging effects
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

    /// Emits anchor IDs for snapping after scroll ends
    var scrollToIdPublisher: AnyPublisher<AnyHashable, Never> {
        scrollToIdSubject.eraseToAnyPublisher()
    }

    /// Scroll anchors
    let topAnchorId: AnyHashable = UUID()
    let bottomAnchorId: AnyHashable = UUID()

    private let scrollToIdSubject = PassthroughSubject<AnyHashable, Never>()
    private let scrollStateSubject = PassthroughSubject<ScrollState, Never>()
    private let scrollOffsetSubject = PassthroughSubject<CGPoint, Never>()

    /// Snap thresholds
    private let collapseThreshold: Double = 0.5
    private let expandThreshold: Double = 0.1

    /// Initial geometry snapshot
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
        // State machine driven by scroll offset
        scrollOffsetSubject
            .receiveOnMain()
            .scan(state) { [weak self] state, scrollOffset in
                guard let self else { return state }
                return self.state(for: state, with: scrollOffset)
            }
            .removeDuplicates()
            .assign(to: &$state)

        // Detects transition from scrolling to idle
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

        // Emits anchor to snap to when scrolling finishes
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
    /// Calculates collapsing state with elastic resistance.
    ///
    /// The raw scroll offset is reduced by a non-linear resistance curve
    /// to simulate a rubber-band effect while collapsing.
    ///
    /// - Parameters:
    ///   - initialHeight: Full height of the container in expanded state
    ///   - offset: Current scroll offset relative to initial position
    ///
    /// - Returns: `.collapsing` with normalized ratio or `.collapsed`
    func collapseState(initialHeight: CGFloat, offset: CGFloat) -> State {
        guard initialHeight > 0 else { return .collapsed }
        let resistanceHeight = resistanceHeight(height: initialHeight, offset: offset)
        let height = offset - resistanceHeight
        let ratio = height / initialHeight
        return ratio < 1 ? .collapsing(ratio: ratio) : .collapsed
    }

    /// Convenience helper that calculates resistance height
    /// using a normalized ratio instead of raw offset.
    func resistanceHeight(ratio: CGFloat) -> CGFloat {
        guard let initialFrame else { return 0 }
        let height = initialFrame.height
        let offset = height * ratio
        return resistanceHeight(height: height, offset: offset)
    }

    /// Converts scroll offset into elastic resistance distance.
    ///
    /// The resistance grows non-linearly as the offset increases,
    /// preventing the collapse from feeling linear or stiff.
    func resistanceHeight(height: CGFloat, offset: CGFloat) -> CGFloat {
        guard height > 0 else { return 0 }
        let resistance = resistanceCurve(x: offset / height)
        return resistance * height
    }

    /// Resistance curve used during collapsing.
    ///
    /// - Uses a squared sine wave to:
    ///   - start with zero resistance
    ///   - peak smoothly in the middle
    ///   - return to zero at the end
    ///
    /// This produces a soft, natural rubber-band feel.
    func resistanceCurve(x: CGFloat) -> CGFloat {
        let correctionFactor = 0.25
        return pow(sin(x * .pi), 2) * correctionFactor
    }
}

// MARK: - Expand state

private extension TangemElasticContainerModel {
    /// Calculates expanding state with elastic "hugging" effect.
    ///
    /// Hugging works opposite to resistance: instead of pushing back,
    /// it softly pulls the content toward the expanded state.
    func expandState(initialHeight: CGFloat, offset: CGFloat) -> State {
        guard initialHeight > 0 else { return .expanded }
        let huggingHeight = huggingHeight(height: initialHeight, offset: offset)
        let height = initialHeight - offset - huggingHeight
        let ratio = height / initialHeight
        return ratio < 1 ? .expanding(ratio: ratio) : .expanded
    }

    /// Convenience helper that calculates hugging height
    /// using a normalized ratio instead of raw offset.
    func huggingHeight(ratio: CGFloat) -> CGFloat {
        guard let initialFrame else { return 0 }
        let height = initialFrame.height
        let offset = height * ratio
        return huggingHeight(height: height, offset: offset)
    }

    /// Converts scroll offset into elastic hugging distance.
    ///
    /// Hugging reduces the effective expansion distance,
    /// making the container feel magnetically attached
    /// to its expanded state.
    func huggingHeight(height: CGFloat, offset: CGFloat) -> CGFloat {
        guard height > 0 else { return 0 }
        let hugging = huggingCurve(x: offset / height)
        return hugging * height
    }

    /// Hugging curve used during expansion.
    ///
    /// Similar to resistance curve but with a smaller correction factor
    /// to keep expansion lighter and more responsive.
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
