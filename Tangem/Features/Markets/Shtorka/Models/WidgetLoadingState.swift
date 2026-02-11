//
//  WidgetLoadingState.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

enum WidgetLoadingState: Hashable {
    case loading
    case loaded
    case error

    var isLoading: Bool {
        switch self {
        case .loading:
            return true
        case .loaded, .error:
            return false
        }
    }

    var isError: Bool {
        switch self {
        case .loading, .loaded:
            return false
        case .error:
            return true
        }
    }
}
