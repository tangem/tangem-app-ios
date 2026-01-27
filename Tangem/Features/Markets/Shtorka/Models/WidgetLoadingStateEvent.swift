//
//  WidgetLoadingStateEvent.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

enum WidgetLoadingStateEvent: Identifiable, Hashable {
    /// All widgets finished loading (some may have errors, some may have succeeded)
    case loaded

    /// All widgets failed with errors
    case allFailed

    /// Initial loading - widgets are loading for the first time
    case initialLoading

    /// Reloading after initial load - some widgets are reloading (e.g., retry after error)
    /// Contains the list of widget types that are currently reloading.
    /// Other widgets should not show loading state in this case.
    case reloading([MarketsWidgetType])

    var id: String {
        switch self {
        case .loaded:
            return "loaded"
        case .allFailed:
            return "all_failed"
        case .initialLoading:
            return "initial_loading"
        case .reloading:
            return "reloading"
        }
    }
}
