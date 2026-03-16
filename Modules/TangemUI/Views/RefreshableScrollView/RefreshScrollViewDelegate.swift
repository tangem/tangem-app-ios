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
    private let willEndDraggingAt: (CGPoint) -> TargetContentOffset?

    private weak var scrollView: UIScrollView?

    /// We can't use UIScrollView.isDragging here
    /// Because it's still true while scroll view is decelerating
    private(set) var dragging: Dragging?

    private var observers: [AnyHashable: WeakObserver] = [:]

    init(willEndDraggingAt: @escaping (CGPoint) -> TargetContentOffset?) {
        self.willEndDraggingAt = willEndDraggingAt
    }

    @MainActor
    func set(scrollView: UIScrollView?) {
        // Do not double the set
        guard self.scrollView == nil else {
            return
        }

        self.scrollView = scrollView

        scrollView?.delegate = self
        observersPerform { observer in
            observer.scrollViewDidSet(scrollView)
        }
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

    func addObserver(_ observer: RefreshScrollViewObserver) {
        let key = ObjectIdentifier(observer)
        observers[key] = WeakObserver(observer)
    }

    func removeObserver(_ observer: RefreshScrollViewObserver) {
        let key = ObjectIdentifier(observer)
        observers.removeValue(forKey: key)
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

    func observersPerform(_ closure: (RefreshScrollViewObserver) -> Void) {
        observers.values.forEach { weakObserver in
            if let observer = weakObserver.value {
                closure(observer)
            }
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
        observersPerform { $0.scrollViewDidScroll?(scrollView) }
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        observersPerform { $0.scrollViewDidZoom?(scrollView) }
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        observersPerform { $0.scrollViewWillBeginDragging?(scrollView) }
        willBeginDragging(scrollView)
    }

    func scrollViewWillEndDragging(
        _ scrollView: UIScrollView,
        withVelocity velocity: CGPoint,
        targetContentOffset: UnsafeMutablePointer<CGPoint>
    ) {
        observersPerform {
            $0.scrollViewWillEndDragging?(
                scrollView,
                withVelocity: velocity,
                targetContentOffset: targetContentOffset
            )
        }
        willEndDragging(scrollView, targetContentOffset: targetContentOffset)
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        observersPerform { $0.scrollViewDidEndDragging?(scrollView, willDecelerate: decelerate) }
    }

    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        observersPerform { $0.scrollViewWillBeginDecelerating?(scrollView) }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        observersPerform { $0.scrollViewDidEndDecelerating?(scrollView) }
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        observersPerform { $0.scrollViewDidEndScrollingAnimation?(scrollView) }
    }

    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        observersPerform { $0.scrollViewWillBeginZooming?(scrollView, with: view) }
    }

    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        observersPerform { $0.scrollViewDidEndZooming?(scrollView, with: view, atScale: scale) }
    }

    func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        observersPerform { $0.scrollViewDidScrollToTop?(scrollView) }
    }

    func scrollViewDidChangeAdjustedContentInset(_ scrollView: UIScrollView) {
        observersPerform { $0.scrollViewDidChangeAdjustedContentInset?(scrollView) }
    }
}

// MARK: - WeakObserver

private final class WeakObserver {
    weak var value: RefreshScrollViewObserver?

    init(_ value: RefreshScrollViewObserver) {
        self.value = value
    }
}
