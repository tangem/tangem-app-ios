//
//  RefreshScrollViewDelegate.swift
//  TangemUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import UIKit

final class RefreshScrollViewDelegate: NSObject {
    private let willEndDraggingAt: (CGPoint) -> TargetContentOffset?

    private weak var scrollView: UIScrollView?
    private weak var internalScrollViewDelegate: UIScrollViewDelegate?

    /// We can't use UIScrollView.isDragging here
    /// Because it's still true while scroll view is decelerating
    private(set) var dragging: Dragging?

    init(willEndDraggingAt: @escaping (CGPoint) -> TargetContentOffset?) {
        self.willEndDraggingAt = willEndDraggingAt
    }

    func set(scrollView: UIScrollView?) {
        // Do not double the set
        guard self.scrollView == nil else {
            return
        }

        self.scrollView = scrollView
        internalScrollViewDelegate = scrollView?.delegate

        scrollView?.delegate = self
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
        internalScrollViewDelegate?.scrollViewDidScroll?(scrollView)
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        internalScrollViewDelegate?.scrollViewDidZoom?(scrollView)
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        internalScrollViewDelegate?.scrollViewWillBeginDragging?(scrollView)
        willBeginDragging(scrollView)
    }

    func scrollViewWillEndDragging(
        _ scrollView: UIScrollView,
        withVelocity velocity: CGPoint,
        targetContentOffset: UnsafeMutablePointer<CGPoint>
    ) {
        internalScrollViewDelegate?.scrollViewWillEndDragging?(scrollView, withVelocity: velocity, targetContentOffset: targetContentOffset)
        willEndDragging(scrollView, targetContentOffset: targetContentOffset)
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        internalScrollViewDelegate?.scrollViewDidEndDragging?(scrollView, willDecelerate: decelerate)
    }

    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        internalScrollViewDelegate?.scrollViewWillBeginDecelerating?(scrollView)
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        internalScrollViewDelegate?.scrollViewDidEndDecelerating?(scrollView)
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        internalScrollViewDelegate?.scrollViewDidEndScrollingAnimation?(scrollView)
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        internalScrollViewDelegate?.viewForZooming?(in: scrollView)
    }

    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        internalScrollViewDelegate?.scrollViewWillBeginZooming?(scrollView, with: view)
    }

    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        internalScrollViewDelegate?.scrollViewDidEndZooming?(scrollView, with: view, atScale: scale)
    }

    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        internalScrollViewDelegate?.scrollViewShouldScrollToTop?(scrollView) ?? true
    }

    func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        internalScrollViewDelegate?.scrollViewDidScrollToTop?(scrollView)
    }

    func scrollViewDidChangeAdjustedContentInset(_ scrollView: UIScrollView) {
        internalScrollViewDelegate?.scrollViewDidChangeAdjustedContentInset?(scrollView)
    }
}
