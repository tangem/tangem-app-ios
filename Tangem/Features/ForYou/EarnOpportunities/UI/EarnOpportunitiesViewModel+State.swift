//
//  EarnOpportunitiesViewModel+State.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension EarnOpportunitiesViewModel {
    enum ViewState: Equatable {
        case loading
        case content(Content)

        struct Content: Equatable {
            /// `nil` hides the subtitle line.
            let subtitle: EarnRewardSubtitle?
            let list: List
        }

        /// Holdings grouped by account, or suggestions when there are none.
        enum List: Equatable {
            case accounts([EarnAccountListItem])
            case suggestions([EarnSuggestionRowData])
        }
    }
}
