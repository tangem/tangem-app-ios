//
//  FeedContainer.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemUI

/// Whatever shows the feed, as the feed sees it. The sheet on the main screen resizes and can be taken away from
/// the feed it holds; a screen of its own does neither, and answers so rather than imitating one.
protocol FeedContainer: AnyObject {
    /// Whether the feed is on screen at all.
    var isPresented: Bool { get }

    /// The size the feed is shown at now.
    var size: ShtorkaSize { get }

    /// Every size the feed has to answer for: the one it is first seen at, and each one the container settles
    /// on afterwards. The sheet builds the feed already rendering its collapsed self, so it has nothing to
    /// report until that changes.
    var sizePublisher: AnyPublisher<ShtorkaSize, Never> { get }

    /// Whether the feed's content has reached the physically collapsed state. This may change during an
    /// interrupted drag even when the settled size does not.
    var contentCollapsedPublisher: AnyPublisher<Bool, Never> { get }

    /// The container has taken the feed off screen for good.
    var dismissPublisher: AnyPublisher<Void, Never> { get }

    /// Show the feed in full.
    func expand()

    /// The feed has pushed a screen, or come back from one.
    func setNavigationActive(_ isActive: Bool)

    func setSearchActive(_ isActive: Bool)
}
