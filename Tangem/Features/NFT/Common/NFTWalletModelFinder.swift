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
    static func isWalletModel(_ walletModel: any WalletModel, equalsTo collectionIdentifier: NFTCollection.ID) -> Bool {
        return isWalletModel(
            walletModel,
            equalsToNFTChain: collectionIdentifier.chain,
            andOwnerAddress: collectionIdentifier.ownerAddress
        )
    }

    static func isWalletModel(_ walletModel: any WalletModel, equalsTo assetIdentifier: NFTAsset.ID) -> Bool {
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
        _ walletModel: any WalletModel,
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
