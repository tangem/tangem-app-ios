//
//  TokensManagementAnalyticsLogger.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

final class TokensManagementAnalyticsLogger {
    func logButtonAddAndOrganize() {
        Analytics.log(.buttonAddAndOrganize)
    }

    func logButtonAddTokens() {
        Analytics.log(.buttonAddTokens)
    }

    func logButtonOrganizeTokens() {
        Analytics.log(.buttonOrganizeTokens)
    }

    func logOrganizeTokensScreenOpened() {
        Analytics.log(.organizeTokensScreenOpened)
    }

    func logButtonByBalance() {
        Analytics.log(.organizeTokensButtonSortByBalance)
    }

    func logButtonGroup() {
        Analytics.log(.organizeTokensButtonGroup)
    }
}
