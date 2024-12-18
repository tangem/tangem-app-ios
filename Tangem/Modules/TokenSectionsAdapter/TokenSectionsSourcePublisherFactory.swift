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
    func makeSourcePublisherForMainScreen(for userWalletModel: UserWalletModel) -> some Publisher<[WalletModel], Never> {
        // Fiat balance changes for the coins and tokens for the user wallet
        let walletModelsBalanceChangesPublisher = userWalletModel
            .totalBalancePublisher
            .filter { !$0.isLoading }
            .withLatestFrom(walletModelsPublisher)
            .eraseToAnyPublisher()

        return [
            walletModelsPublisher(for: userWalletModel),
            walletModelsBalanceChangesPublisher,
        ].merge()
    }

    /// Fix [REDACTED_INFO]
    func makeSourcePublisher(for userWalletModel: UserWalletModel) -> some Publisher<[WalletModel], Never> {
        return walletModelsPublisher(for: userWalletModel)
    }

    // The contents of the coins and tokens collection for the user wallet
    private func walletModelsPublisher(for userWalletModel: UserWalletModel) -> some Publisher<[WalletModel], Never> {
        userWalletModel
            .walletModelsManager
            .walletModelsPublisher
            .share(replay: 1)
            .eraseToAnyPublisher()
    }
}
