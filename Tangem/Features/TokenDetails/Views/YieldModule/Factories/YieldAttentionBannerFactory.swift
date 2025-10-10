//
//  YieldAttentionBannerFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

enum YieldAttentionBannerFactory {
    static func makeNotEnoughFeeCurrencyBanner(
        feeTokenItem: TokenItem,
        navigationAction: @MainActor @Sendable @escaping () -> Void
    ) -> YieldModuleViewConfigs.YieldModuleNotificationBannerParams {
        .notEnoughFeeCurrency(
            feeCurrencyName: feeTokenItem.name,
            tokenIcon: NetworkImageProvider().provide(by: feeTokenItem.blockchain, filled: true),
            buttonAction: navigationAction
        )
    }

    static func makeApproveRequiredBanner(
        navigationAction: @MainActor @Sendable @escaping () -> Void
    ) -> YieldModuleViewConfigs.YieldModuleNotificationBannerParams {
        .approveNeeded(buttonAction: navigationAction)
    }
}
