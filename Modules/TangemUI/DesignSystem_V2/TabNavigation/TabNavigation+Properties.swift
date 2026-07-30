//
//  TabNavigation+Properties.swift
//  TangemModules
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemAssets

public protocol TabNavigationItem: Identifiable, Hashable {
    var title: String { get }
    var icon: ImageType? { get }
    var counter: String? { get }
}

public extension TabNavigationItem {
    var icon: ImageType? { nil }
    var counter: String? { nil }
}

public enum TabNavigationVariant: Sendable, Hashable, CaseIterable {
    case material
    case transparent
}

public extension TabNavigation {
    typealias Variant = TabNavigationVariant
}
