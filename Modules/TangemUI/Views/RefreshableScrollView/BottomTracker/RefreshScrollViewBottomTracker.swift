//
//  RefreshScrollViewBottomTracker.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

/// A helper that publishes the distance from the current scroll position
/// to the bottom of the scroll view content.
///
/// Values are updated on each scroll event:
/// - `< 0` — not yet at bottom
/// - `= 0` — reached bottom
/// - `> 0` — overscrolled beyond bottom
///
/// Emissions are deduplicated and delivered on the main thread.
public final class RefreshScrollViewBottomTracker: ObservableObject {
    public let distancePublisher: AnyPublisher<CGFloat, Never>

    private let distanceSubject = PassthroughSubject<CGFloat, Never>()

    private let scrollInteractor: RefreshScrollViewInteractor

    private var bag: Set<AnyCancellable> = []

    public init(scrollInteractor: RefreshScrollViewInteractor) {
        self.scrollInteractor = scrollInteractor
        distancePublisher = distanceSubject.eraseToAnyPublisher()
        bind()
    }
}

// MARK: - Private methods

private extension RefreshScrollViewBottomTracker {
    func bind() {
        scrollInteractor.eventPublisher
            .withWeakCaptureOf(self)
            .compactMap { tracker, event in
                tracker.distance(event: event)
            }
            .removeDuplicates()
            .receiveOnMain()
            .subscribe(distanceSubject)
            .store(in: &bag)
    }

    func distance(event: RefreshScrollViewEvent) -> CGFloat? {
        guard
            case .didScroll(let offset) = event,
            let contentSize = scrollInteractor.contentSize,
            let frameSize = scrollInteractor.frameSize
        else {
            return nil
        }

        return offset.y + frameSize.height - contentSize.height
    }
}
