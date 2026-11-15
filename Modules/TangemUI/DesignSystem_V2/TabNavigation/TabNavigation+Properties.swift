//
//  TabNavigation+Properties.swift
//  TangemModules
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemAssets

public protocol TabNavigationItem: Identifiable, Hashable {
    var title: String { get }
    var start: TabNavigationItemStart? { get }
    var counter: String? { get }
}

public extension TabNavigationItem {
    var start: TabNavigationItemStart? { nil }
    var counter: String? { nil }
}

public enum TabNavigationItemStart: Hashable, Sendable {
    case icon(ImageType)
    case walletThumbnail(ThumbnailWalletViewType)
}

public enum TabNavigationVariant: Sendable, Hashable, CaseIterable {
    case material
    case transparent
}

public extension TabNavigation {
    typealias Variant = TabNavigationVariant
}
