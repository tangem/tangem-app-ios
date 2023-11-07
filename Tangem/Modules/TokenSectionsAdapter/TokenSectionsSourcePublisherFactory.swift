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
    func makeSourcePublisher(for walletModelsManager: WalletModelsManager) -> some Publisher<[WalletModel], Never> {
        // The contents of the coins and tokens collection for the user wallet
        let walletModelsPublisher = walletModelsManager
            .walletModelsPublisher
            .share(replay: 1)
            .eraseToAnyPublisher()

        // Fiat/balance changes for the coins and tokens for the user wallet
        let walletModelsDidChangePublisher = walletModelsPublisher
            .flatMap { walletModels in
                return walletModels
                    .map(\.walletDidChangePublisher)
                    .merge()
                    .mapToValue(walletModels)
                    .filter { $0.allSatisfy { !$0.state.isLoading } }
            }
            .withLatestFrom(walletModelsPublisher)
            .eraseToAnyPublisher()

        return [
            walletModelsPublisher,
            walletModelsDidChangePublisher,
        ].merge()
    }
}

// MARK: - Convenience extensions

extension TokenSectionsSourcePublisherFactory {
    func makeSourcePublisher(for userWalletModel: UserWalletModel) -> some Publisher<[WalletModel], Never> {
        return makeSourcePublisher(for: userWalletModel.walletModelsManager)
    }
}
