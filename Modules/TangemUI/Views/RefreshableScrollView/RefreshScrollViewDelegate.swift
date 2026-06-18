//
//  RefreshScrollViewDelegate.swift
//  TangemUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import UIKit
import TangemFoundation

final class RefreshScrollViewDelegate: NSObject {
    private let interactor: RefreshScrollViewInteractor
    private let willEndDraggingAt: (CGPoint) -> TargetContentOffset?

    private weak var scrollView: UIScrollView?

    /// We can't use UIScrollView.isDragging here
    /// Because it's still true while scroll view is decelerating
    private(set) var dragging: Dragging?

    init(
        interactor: RefreshScrollViewInteractor,
        willEndDraggingAt: @escaping (CGPoint) -> TargetContentOffset?
    ) {
        self.interactor = interactor
        self.willEndDraggingAt = willEndDraggingAt
    }

    func set(scrollView: UIScrollView) {
        // Do not double the set
        guard self.scrollView == nil else {
            return
        }

        self.scrollView = scrollView
        scrollView.delegate = self

        interactor.set(scrollView: scrollView)
    }

    func scrollToTop() {
        guard let scrollView else {
            assertionFailure("UIScrollView isn't set")
            return
        }

        let topInset = topInset(scrollView: scrollView)
        let top = CGPoint(x: scrollView.safeAreaInsets.left, y: -topInset)
        scrollView.setContentOffset(top, animated: true)
    }
}

// MARK: - Custom implementation

private extension RefreshScrollViewDelegate {
    func willBeginDragging(_ scrollView: UIScrollView) {
        dragging = .init(
            startOffset: .init(
                x: scrollView.contentOffset.x,
                y: scrollView.contentOffset.y + topInset(scrollView: scrollView)
            )
        )
    }

    func willEndDragging(_ scrollView: UIScrollView, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        dragging = nil

        let topInset = topInset(scrollView: scrollView)
        let y = targetContentOffset.pointee.y + topInset
        let point = CGPoint(x: targetContentOffset.pointee.x, y: y)

        switch willEndDraggingAt(point) {
        case .none:
            break
        case .top:
            targetContentOffset.pointee = .init(
                x: targetContentOffset.pointee.x,
                y: -topInset
            )
        }
    }

    func topInset(scrollView: UIScrollView) -> CGFloat {
        if #available(iOS 17.0, *) {
            scrollView.safeAreaInsets.top
        } else {
            scrollView.contentInset.top
        }
    }
}

// MARK: - Models

extension RefreshScrollViewDelegate {
    enum TargetContentOffset {
        case top
    }

    struct Dragging {
        let startOffset: CGPoint
    }
}

// MARK: - UIScrollViewDelegate

extension RefreshScrollViewDelegate: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        interactor.send(event: .didScroll(offset: scrollView.contentOffset))
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        interactor.send(event: .didZoom)
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        interactor.send(event: .willBeginDragging)
        willBeginDragging(scrollView)
    }

    func scrollViewWillEndDragging(
        _ scrollView: UIScrollView,
        withVelocity velocity: CGPoint,
        targetContentOffset: UnsafeMutablePointer<CGPoint>
    ) {
        interactor.send(event: .willEndDragging(velocity: velocity))

        if let snapped = interactor.targetContentOffsetProvider?(targetContentOffset.pointee, velocity) {
            targetContentOffset.pointee = snapped
        }

        willEndDragging(scrollView, targetContentOffset: targetContentOffset)
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        interactor.send(event: .didEndDragging(willDecelerate: decelerate))
    }

    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        interactor.send(event: .willBeginDecelerating)
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        interactor.send(event: .didEndDecelerating)
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        interactor.send(event: .didEndScrollingAnimation)
    }

    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        interactor.send(event: .willBeginZooming)
    }

    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        interactor.send(event: .didEndZooming(scale: scale))
    }

    func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        interactor.send(event: .didScrollToTop)
    }

    func scrollViewDidChangeAdjustedContentInset(_ scrollView: UIScrollView) {
        interactor.send(event: .didChangeAdjustedContentInset)
    }
}
