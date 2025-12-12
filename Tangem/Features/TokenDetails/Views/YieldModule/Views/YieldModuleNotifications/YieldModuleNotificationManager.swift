//
//  YieldModuleNotificationManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

struct YieldModuleNotificationManager {
    private let tokenItem: TokenItem
    private let feeTokenItem: TokenItem

    // MARK: - Init

    init(tokenItem: TokenItem, feeTokenItem: TokenItem) {
        self.tokenItem = tokenItem
        self.feeTokenItem = feeTokenItem
    }

    // MARK: - Public Implementation

    func createApproveRequiredNotification(action: @escaping () -> Void) -> YieldModuleNotificationBannerParams {
        .approveNeeded { action() }
    }

    func createHasUndepositedAmountsNotification(undepositedAmount: String) -> YieldModuleNotificationBannerParams {
        .hasUndepositedAmounts(amount: undepositedAmount, currencySymbol: tokenItem.currencySymbol)
    }

    func createNotEnoughFeeCurrencyNotification(action: @escaping () -> Void) -> YieldModuleNotificationBannerParams {
        .notEnoughFeeCurrency(
            feeCurrencyName: feeTokenItem.name,
            tokenIcon: NetworkImageProvider().provide(by: feeTokenItem.blockchain, filled: true),
            buttonAction: { action() }
        )
    }

    func createFeeUnreachableNotification(action: @escaping () -> Void) -> YieldModuleNotificationBannerParams {
        .feeUnreachable(buttonAction: { action() })
    }

    func createHighFeesNotification() -> YieldModuleNotificationBannerParams {
        .highFees
    }
}
