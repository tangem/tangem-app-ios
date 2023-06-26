//
//  Toolbar+Compat.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

extension View {
    /// Swift doesn't support array splatting for variadic parameters, therefore only a single `toolbarPlacement` parameter is accepted.
    @ViewBuilder
    func toolbarBackgroundCompat(
        _ visibilityCompat: VisibilityCompat,
        for toolbarPlacement: ToolbarPlacementCompat
    ) -> some View {
        if #available(iOS 16.0, *) {
            let visibility = Self.visibility(from: visibilityCompat)
            let bars = Self.toolbarPlacement(from: toolbarPlacement)
            toolbarBackground(visibility, for: bars)
        } else {
            self
        }
    }
}

// MARK: - Auxiliary types

@frozen
enum ToolbarPlacementCompat: Hashable, CaseIterable {
    case automatic
    case bottomBar
    case navigationBar
    case tabBar
}

@frozen
enum VisibilityCompat: Hashable, CaseIterable {
    case automatic
    case visible
    case hidden
}

// MARK: - Private implementation

private extension View {
    @available(iOS 16.0, *)
    private static func visibility(
        from visibility: VisibilityCompat
    ) -> Visibility {
        switch visibility {
        case .automatic:
            return .automatic
        case .visible:
            return .visible
        case .hidden:
            return .hidden
        }
    }

    @available(iOS 16.0, *)
    private static func toolbarPlacement(
        from toolbarPlacement: ToolbarPlacementCompat
    ) -> ToolbarPlacement {
        switch toolbarPlacement {
        case .automatic:
            return .automatic
        case .bottomBar:
            return .bottomBar
        case .navigationBar:
            return .navigationBar
        case .tabBar:
            return .tabBar
        }
    }
}
