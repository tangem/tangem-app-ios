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
            let subtitle: EarnRewardSubtitle
            let accounts: [EarnAccountListItem]
        }
    }
}
