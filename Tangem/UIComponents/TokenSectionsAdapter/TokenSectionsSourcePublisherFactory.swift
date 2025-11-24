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
    func makeSourcePublisher(for userWalletModel: UserWalletModel) -> some Publisher<[any WalletModel], Never> {
        // accounts_fixes_needed_none
        let walletModelsPublisher = walletModelsPublisher(for: userWalletModel.walletModelsManager)
            .eraseToAnyPublisher()

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

    private func walletModelsPublisher(for walletModelsManager: any WalletModelsManager) -> some Publisher<[any WalletModel], Never> {
        // [REDACTED_TODO_COMMENT]
        walletModelsManager
            .walletModelsPublisher
            .share(replay: 1)
    }
}
