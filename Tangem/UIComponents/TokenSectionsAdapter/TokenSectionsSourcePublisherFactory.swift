//
//  TokenSectionsSourcePublisherFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt

/// A factory that creates a so-called `source publisher` for use with `TokenSectionsAdapter.organizedSections(from:on:)`
/// method as the source of truth for creating token sections.
struct TokenSectionsSourcePublisherFactory {
    @available(iOS, deprecated: 100000.0, message: "Legacy factory for UI w/o accounts support, will be removed in the future ([REDACTED_INFO])")
    func makeSourcePublisher(
        for userWalletModel: UserWalletModel
    ) -> some Publisher<[any WalletModel], Never> {
        // accounts_fixes_needed_none
        return makeSourcePublisher(
            walletModelsPublisher: userWalletModel.walletModelsManager.walletModelsPublisher,
            totalBalancePublisher: userWalletModel.totalBalancePublisher
        )
    }

    func makeSourcePublisher(
        for cryptoAccountModel: any CryptoAccountModel,
        in userWalletModel: UserWalletModel
    ) -> some Publisher<[any WalletModel], Never> {
        return makeSourcePublisher(
            walletModelsPublisher: cryptoAccountModel.walletModelsManager.walletModelsPublisher,
            totalBalancePublisher: userWalletModel.totalBalancePublisher
        )
    }

    private func makeSourcePublisher(
        walletModelsPublisher: some Publisher<[any WalletModel], Never>,
        totalBalancePublisher: some Publisher<TotalBalanceState, Never>
    ) -> some Publisher<[any WalletModel], Never> {
        let walletModelsPublisher = walletModelsPublisher
            .share(replay: 1)

        // Fiat balance changes for the coins and tokens for the user wallet
        let walletModelsBalanceChangesPublisher = totalBalancePublisher
            .filter { !$0.isLoading }
            .withLatestFrom(walletModelsPublisher)

        return [
            walletModelsPublisher.eraseToAnyPublisher(),
            walletModelsBalanceChangesPublisher.eraseToAnyPublisher(),
        ].merge()
    }
}
