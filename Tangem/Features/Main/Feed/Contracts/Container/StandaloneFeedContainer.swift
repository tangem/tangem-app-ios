//
//  StandaloneFeedContainer.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemUI

/// A screen of its own: the feed fills it from the start, so there is nothing to expand and no second size to
/// settle on. It is dismissed whole rather than handing the feed back, so it has no dismissal to report either.
final class StandaloneFeedContainer: FeedContainer {
    let isPresented = true
    let size: ShtorkaSize = .full

    /// Full and never anything else — but reported, because the feed is seen the moment the screen is up.
    var sizePublisher: AnyPublisher<ShtorkaSize, Never> {
        Just(.full).eraseToAnyPublisher()
    }

    var dismissPublisher: AnyPublisher<Void, Never> {
        Empty(completeImmediately: false).eraseToAnyPublisher()
    }

    func expand() {}

    func setNavigationActive(_ isActive: Bool) {}
}
