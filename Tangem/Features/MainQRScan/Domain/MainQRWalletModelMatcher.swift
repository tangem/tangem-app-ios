//
//  MainQRWalletModelMatcher.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk

struct MainQRWalletModelMatcher {
    private let userWalletRepository: UserWalletRepository

    init(userWalletRepository: UserWalletRepository) {
        self.userWalletRepository = userWalletRepository
    }

    func collectContext() -> ResolvedContext {
        let allMatches = collectAllWalletModels()
        let allTokenItems = allMatches.map(\.walletModel.tokenItem)
        return ResolvedContext(allMatches: allMatches, allTokenItems: allTokenItems)
    }

    func filterMatches(_ allMatches: [WalletModelMatch], for tokenItems: [TokenItem]) -> [WalletModelMatch] {
        let compatibleTokenItems = Set(tokenItems)
        return allMatches.filter { compatibleTokenItems.contains($0.walletModel.tokenItem) }
    }

    func filterMatches(_ allMatches: [WalletModelMatch], for blockchains: [Blockchain]) -> [WalletModelMatch] {
        let compatibleBlockchains = Set(blockchains)
        return allMatches.filter { compatibleBlockchains.contains($0.walletModel.tokenItem.blockchain) }
    }

    private func collectAllWalletModels() -> [WalletModelMatch] {
        var matches: [WalletModelMatch] = []

        for userWalletModel in userWalletRepository.models {
            let walletModels = AccountsFeatureAwareWalletModelsResolver.walletModels(for: userWalletModel)

            for walletModel in walletModels {
                matches.append(
                    WalletModelMatch(
                        walletModel: walletModel,
                        userWalletInfo: userWalletModel.userWalletInfo
                    )
                )
            }
        }

        return matches
    }
}

// MARK: - Supporting Types

extension MainQRWalletModelMatcher {
    struct ResolvedContext {
        let allMatches: [WalletModelMatch]
        let allTokenItems: [TokenItem]

        var allBlockchains: [Blockchain] {
            allTokenItems.map(\.blockchain)
        }
    }
}

struct WalletModelMatch {
    let walletModel: any WalletModel
    let userWalletInfo: UserWalletInfo
}
