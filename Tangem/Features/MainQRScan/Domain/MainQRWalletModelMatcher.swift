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
        collectContext(from: userWalletRepository.models)
    }

    func collectContext(from userWalletModels: [any UserWalletModel]) -> ResolvedContext {
        let allMatches = collectAllWalletModels(from: userWalletModels)
        let allTokenItems = allMatches.map(\.walletModel.tokenItem)

        var seenBlockchains = Set<Blockchain>()
        var uniqueBlockchains: [Blockchain] = []
        uniqueBlockchains.reserveCapacity(allTokenItems.count)
        for tokenItem in allTokenItems {
            let blockchain = tokenItem.blockchain
            if seenBlockchains.insert(blockchain).inserted {
                uniqueBlockchains.append(blockchain)
            }
        }

        return ResolvedContext(allMatches: allMatches, allTokenItems: allTokenItems, allBlockchains: uniqueBlockchains)
    }

    func filterMatches(_ allMatches: [MainQRWalletModelMatch], for tokenItems: [TokenItem]) -> [MainQRWalletModelMatch] {
        let compatibleTokenItems = Set(tokenItems)
        return allMatches.filter { compatibleTokenItems.contains($0.walletModel.tokenItem) }
    }

    func filterMatches(_ allMatches: [MainQRWalletModelMatch], for blockchains: [Blockchain]) -> [MainQRWalletModelMatch] {
        let compatibleBlockchains = Set(blockchains)
        return allMatches.filter { compatibleBlockchains.contains($0.walletModel.tokenItem.blockchain) }
    }

    private func collectAllWalletModels(from userWalletModels: [any UserWalletModel]) -> [MainQRWalletModelMatch] {
        var matches: [MainQRWalletModelMatch] = []

        for userWalletModel in userWalletModels {
            let walletModels = AccountsFeatureAwareWalletModelsResolver.walletModels(for: userWalletModel)

            for walletModel in walletModels {
                matches.append(
                    MainQRWalletModelMatch(
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
        let allMatches: [MainQRWalletModelMatch]
        let allTokenItems: [TokenItem]
        let allBlockchains: [Blockchain]
    }
}

struct MainQRWalletModelMatch {
    let walletModel: any WalletModel
    let userWalletInfo: UserWalletInfo
}
