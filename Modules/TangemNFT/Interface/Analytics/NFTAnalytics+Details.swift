//
//  NFTAnalytics+.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

public extension NFTAnalytics {
    struct Details {
        let logReadMoreTapped: () -> Void
        let logSeeAllTapped: () -> Void
        let logExploreTapped: () -> Void
        let logSendTapped: () -> Void

        public init(
            logReadMoreTapped: @escaping () -> Void,
            logSeeAllTapped: @escaping () -> Void,
            logExploreTapped: @escaping () -> Void,
            logSendTapped: @escaping () -> Void
        ) {
            self.logReadMoreTapped = logReadMoreTapped
            self.logSeeAllTapped = logSeeAllTapped
            self.logExploreTapped = logExploreTapped
            self.logSendTapped = logSendTapped
        }
    }
}
