//
//  RefreshScrollViewInteractor.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import UIKit

public final class RefreshScrollViewInteractor: ObservableObject {
    public var initialScrollOffset: CGPoint? { _initialScrollOffset }
    public var frameSize: CGSize? { scrollView?.frame.size }
    public var contentSize: CGSize? { scrollView?.contentSize }
    public var currentScrollOffset: CGPoint? { scrollView?.contentOffset }
    public let eventPublisher: AnyPublisher<RefreshScrollViewEvent, Never>

    @Published public private(set) var visibleBodyHeight: CGFloat = 0

    @MainActor
    public var targetContentOffsetProvider: ((_ proposed: CGPoint, _ velocity: CGPoint) -> CGPoint?)?

    private let eventSubject = PassthroughSubject<RefreshScrollViewEvent, Never>()

    private var _initialScrollOffset: CGPoint?
    private weak var scrollView: UIScrollView?

    init() {
        eventPublisher = eventSubject
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    public func setContentOffset(_ offset: CGPoint, animated: Bool) {
        scrollView?.setContentOffset(offset, animated: animated)
    }

    func set(scrollView: UIScrollView) {
        self.scrollView = scrollView
        _initialScrollOffset = scrollView.contentOffset
        updateVisibleBodyHeight()
    }

    func send(event: RefreshScrollViewEvent) {
        eventSubject.send(event)
        switch event {
        case .didChangeAdjustedContentInset, .didScroll:
            updateVisibleBodyHeight()
        default:
            break
        }
    }

    private func updateVisibleBodyHeight() {
        guard let scrollView else { return }
        // RefreshScrollView applies refresh-state top padding via `safeAreaPadding(.top:)` on iOS 17+
        // (bumps `safeAreaInsets.top`, leaves `contentInset.top` at 0) and via `padding(.top:)` on
        // iOS 16 (auto-flows through `contentInset.top`). Read whichever the current OS populates.
        let topInset: CGFloat
        if #available(iOS 17.0, *) {
            topInset = scrollView.safeAreaInsets.top
        } else {
            topInset = scrollView.contentInset.top
        }
        let newValue = max(0, scrollView.frame.height - topInset)
        if newValue != visibleBodyHeight {
            visibleBodyHeight = newValue
        }
    }
}
