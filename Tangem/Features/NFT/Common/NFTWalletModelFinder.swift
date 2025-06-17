//
//  NFTWalletModelFinder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemNFT

enum NFTWalletModelFinder {
    static func isWalletModel(_ walletModel: some WalletModel, equalsTo collectionIdentifier: NFTCollection.ID) -> Bool {
        return isWalletModel(
            walletModel,
            equalsToNFTChain: collectionIdentifier.chain,
            andOwnerAddress: collectionIdentifier.ownerAddress
        )
    }

    static func isWalletModel(_ walletModel: some WalletModel, equalsTo assetIdentifier: NFTAsset.ID) -> Bool {
        return isWalletModel(
            walletModel,
            equalsToNFTChain: assetIdentifier.chain,
            andOwnerAddress: assetIdentifier.ownerAddress
        )
    }

    static func findWalletModel(
        for collectionIdentifier: NFTCollection.ID,
        in walletModels: [any WalletModel]
    ) -> (any WalletModel)? {
        return walletModels.first { isWalletModel($0, equalsTo: collectionIdentifier) }
    }

    static func findWalletModel(
        for assetIdentifier: NFTAsset.ID,
        in walletModels: [any WalletModel]
    ) -> (any WalletModel)? {
        return walletModels.first { isWalletModel($0, equalsTo: assetIdentifier) }
    }

    // MARK: - Private implementation

    private static func isWalletModel(
        _ walletModel: some WalletModel,
        equalsToNFTChain nftChain: NFTChain,
        andOwnerAddress ownerAddress: String
    ) -> Bool {
        guard
            walletModel.isMainToken,
            let walletModelNFTChain = NFTChainConverter.convert(walletModel.tokenItem.blockchain)
        else {
            return false
        }

        return walletModelNFTChain == nftChain && walletModel.addresses.contains { $0.value.caseInsensitiveEquals(to: ownerAddress) }
    }
}

// MARK: - Convenience extensions

extension NFTWalletModelFinder {
    static func isWalletModel(_ walletModel: some WalletModel, equalsTo collection: NFTCollection) -> Bool {
        return isWalletModel(walletModel, equalsTo: collection.id)
    }

    static func isWalletModel(_ walletModel: some WalletModel, equalsTo asset: NFTAsset) -> Bool {
        return isWalletModel(walletModel, equalsTo: asset.id)
    }

    static func findWalletModel(
        for collection: NFTCollection,
        in walletModels: [any WalletModel]
    ) -> (any WalletModel)? {
        return findWalletModel(for: collection.id, in: walletModels)
    }

    static func findWalletModel(
        for asset: NFTAsset,
        in walletModels: [any WalletModel]
    ) -> (any WalletModel)? {
        return findWalletModel(for: asset.id, in: walletModels)
    }
}
