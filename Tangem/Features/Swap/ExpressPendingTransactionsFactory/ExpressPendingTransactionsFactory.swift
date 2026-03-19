//
//  ExpressPendingTransactionsFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemExpress

struct ExpressPendingTransactionsFactory {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    let userWalletInfo: UserWalletInfo
    let tokenItem: TokenItem
    let walletModelUpdater: (any WalletModelUpdater)?

    func makePendingExpressTransactionsManager() -> any PendingExpressTransactionsManager {
        let tokenEnricher = CommonTokenEnricher(
            supportedBlockchains: userWalletInfo.config.supportedBlockchains
        )

        let expressRefundedTokenHandler = CommonExpressRefundedTokenHandler(
            tokenEnricher: tokenEnricher
        )

        let expressAPIProviderResolver = ExpressAPIProviderResolver(
            defaultUserId: userWalletInfo.id.stringValue,
            providerFactory: makeExpressAPIProvider(userId:)
        )

        let pendingExpressTransactionsManager = CommonPendingExpressTransactionsManager(
            userWalletId: userWalletInfo.id.stringValue,
            tokenItem: tokenItem,
            walletModelUpdater: walletModelUpdater,
            expressAPIProviderResolver: expressAPIProviderResolver,
            expressRefundedTokenHandler: expressRefundedTokenHandler
        )

        let pendingOnrampTransactionsManager = CommonPendingOnrampTransactionsManager(
            userWalletId: userWalletInfo.id.stringValue,
            tokenItem: tokenItem,
            expressAPIProvider: expressAPIProviderResolver.provider(for: nil)
        )

        return CompoundPendingTransactionsManager(
            first: pendingExpressTransactionsManager,
            second: pendingOnrampTransactionsManager
        )
    }

    private func makeExpressAPIProvider(userId: String) -> ExpressAPIProvider {
        let refcode: Refcode? = if userId == userWalletInfo.id.stringValue {
            userWalletInfo.refcode
        } else {
            userWalletRepository.models
                .first(where: { $0.userWalletId.stringValue == userId })?
                .refcodeProvider?.getRefcode()
        }

        return ExpressAPIProviderFactory().makeExpressAPIProvider(userId: userId, refcode: refcode)
    }
}
