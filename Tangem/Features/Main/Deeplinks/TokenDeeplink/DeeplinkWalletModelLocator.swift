//
//  DeeplinkWalletModelLocator.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Resolves a `UserWalletModel` and a concrete `WalletModel` from token deeplink parameters.
/// Shared by the various deeplink route handlers (token, staking, yield, referral, etc.).
struct DeeplinkWalletModelLocator {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    func findUserWalletModel(userWalletModelId: String?) -> (any UserWalletModel)? {
        guard let userWalletModelId else {
            return userWalletRepository.selectedModel
        }

        return userWalletRepository.models.first { $0.userWalletId.stringValue == userWalletModelId }
    }

    func findWalletModel(
        in userWalletModel: any UserWalletModel,
        tokenId: String,
        networkId: String,
        derivation: String?
    ) -> (any WalletModel)? {
        var walletModels = AccountWalletModelsAggregator.walletModels(from: userWalletModel.accountModelsManager)

        // If derivation is missing, prefer main account's wallet model - this is why we sort them here
        walletModels.sort { first, second in
            let isFirstMainAccount = first.account?.isMainAccount ?? false
            let isSecondMainAccount = second.account?.isMainAccount ?? false
            return isFirstMainAccount && !isSecondMainAccount
        }

        return findWalletModel(
            in: walletModels,
            tokenId: tokenId,
            networkId: networkId,
            derivation: derivation
        )
    }

    private func findWalletModel(
        in walletModels: [any WalletModel],
        tokenId: String,
        networkId: String,
        derivation: String?
    ) -> (any WalletModel)? {
        // Strict match if derivation is provided
        if let derivation = derivation?.nilIfEmpty {
            return walletModels.first { isMatch($0, tokenId: tokenId, networkId: networkId, derivationPath: derivation) }
        }

        // Loose match with fallback if derivation is not provided
        let matchingModels = walletModels.filter { isMatch($0, tokenId: tokenId, networkId: networkId, derivationPath: nil) }
        return matchingModels.first(where: { !$0.isCustom }) ?? matchingModels.first
    }

    private func isMatch(_ model: any WalletModel, tokenId: String, networkId: String, derivationPath: String?) -> Bool {
        let idMatch = model.tokenItem.id == tokenId
        let networkMatch = model.tokenItem.blockchain.networkId == networkId
        let derivationPathMatch = derivationPath.map { $0 == model.tokenItem.blockchainNetwork.derivationPath?.rawPath } ?? true
        return idMatch && networkMatch && derivationPathMatch
    }
}
