//
//  FeedWidgetsFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum FeedWidgetsFactory {
    // [REDACTED_TODO_COMMENT]
    static func makeWidgets() -> [FeedWidget] {
        [
            .forYou,
            .addAccount,
            .startEarning(FeedEarnWidgetState(maxAPY: Constants.placeholderAPY, tokenSymbol: nil)),
            .tangemPay,
            .referFriend(reward: Constants.placeholderReward),
        ]
    }
}

// MARK: - Constants

private extension FeedWidgetsFactory {
    enum Constants {
        static let placeholderAPY: Decimal = 0.0557
        static let placeholderReward = "$5"
    }
}
