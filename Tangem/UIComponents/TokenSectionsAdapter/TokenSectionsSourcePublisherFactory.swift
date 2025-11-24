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
    func makeSourcePublisherForMainScreen(for userWalletModel: UserWalletModel) -> some Publisher<[any WalletModel], Never> {
        // accounts_fixes_needed_main
        let walletModelsPublisher = walletModelsPublisher(for: userWalletModel.walletModelsManager).eraseToAnyPublisher()

        // Fiat balance changes for the coins and tokens for the user wallet
        let walletModelsBalanceChangesPublisher = userWalletModel
            .totalBalancePublisher
            .filter { !$0.isLoading }
            .withLatestFrom(walletModelsPublisher)
            .eraseToAnyPublisher()

        return [
            walletModelsPublisher,
            walletModelsBalanceChangesPublisher,
        ].merge()
    }

    func makeSourcePublisher(for cryptoAccountModel: any CryptoAccountModel) -> some Publisher<[any WalletModel], Never> {
        return walletModelsPublisher(for: cryptoAccountModel.walletModelsManager)
    }

    /// The contents of the coins and tokens collection for the user wallet
    private func walletModelsPublisher(for walletModelsManager: any WalletModelsManager) -> some Publisher<[any WalletModel], Never> {
        walletModelsManager
            .walletModelsPublisher
            .share(replay: 1)
    }
}
