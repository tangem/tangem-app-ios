//
//  ForYouTokenRow.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// A single portfolio review row. A row is loading or resolved *as a whole*: while every underlying
/// balance is still loading it renders as a full-row shimmer, and only once resolved does it show the
/// real icon, symbol and values. Mixed states resolve to `.content` (the loading parts contribute nothing).
enum ForYouTokenRow: Identifiable, Equatable {
    case loading(id: String)
    case content(ForYouTokenRowData)

    var id: String {
        switch self {
        case .loading(let id): id
        case .content(let data): data.id
        }
    }

    /// The resolved content, or `nil` while the row is still a loading placeholder.
    var content: ForYouTokenRowData? {
        switch self {
        case .loading: nil
        case .content(let data): data
        }
    }
}
