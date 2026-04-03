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

public protocol RefreshScrollViewInteractor {
    var initialScrollOffset: CGPoint? { get }
    var frameSize: CGSize? { get }
    var contentSize: CGSize? { get }
    var eventPublisher: AnyPublisher<RefreshScrollViewEvent, Never> { get }

    func setContentOffset(_ offset: CGPoint, animated: Bool)
}

// MARK: - CommonRefreshScrollViewInteractor

public final class CommonRefreshScrollViewInteractor: RefreshScrollViewInteractor {
    public var initialScrollOffset: CGPoint? { _initialScrollOffset }
    public var frameSize: CGSize? { scrollView?.frame.size }
    public var contentSize: CGSize? { scrollView?.contentSize }
    public let eventPublisher: AnyPublisher<RefreshScrollViewEvent, Never>

    private let eventSubject = PassthroughSubject<RefreshScrollViewEvent, Never>()

    private var _initialScrollOffset: CGPoint?
    private weak var scrollView: UIScrollView?

    init() {
        eventPublisher = eventSubject.eraseToAnyPublisher()
    }

    public func setContentOffset(_ offset: CGPoint, animated: Bool) {
        scrollView?.setContentOffset(offset, animated: animated)
    }

    func set(scrollView: UIScrollView) {
        self.scrollView = scrollView
        _initialScrollOffset = scrollView.contentOffset
    }

    func send(event: RefreshScrollViewEvent) {
        eventSubject.send(event)
    }
}
