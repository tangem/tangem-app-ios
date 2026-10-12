//
//  FeedDetentReporting.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

/// The heights a container computes its detents from. Only the top of the feed measures them: the views below
/// hand their measurements up instead of knowing about the container.
protocol FeedDetentReporting: AnyObject {
    func report(searchBar height: CGFloat)
    func report(widgets height: CGFloat)
    func report(tabChips height: CGFloat)
}

extension EnvironmentValues {
    /// Set by a container that resizes, absent in one of a fixed size — which asks for no measurements, having
    /// no detents to place them between.
    @Entry var feedDetentReporting: (any FeedDetentReporting)?
}
