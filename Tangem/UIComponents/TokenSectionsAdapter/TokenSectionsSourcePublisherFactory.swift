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
