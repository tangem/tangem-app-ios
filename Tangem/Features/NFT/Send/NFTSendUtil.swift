//
//  NFTSendUtil.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemNFT
import BlockchainSdk

struct NFTSendUtil {
    /// - Note: Amount is fixed for NFTs.
    let amountToSend: Decimal

    private let walletModel: any WalletModel
    private let userWalletModel: UserWalletModel

    init(walletModel: any WalletModel, userWalletModel: UserWalletModel) {
        self.walletModel = walletModel
        self.userWalletModel = userWalletModel
        amountToSend = 1 // We currently support sending only a single NFT asset per transaction, even for ERC1155
    }

    /// NFTs require specially prepared and created `SendCoordinator.Options` in order for the Send flow to work properly.
    func makeOptions(for asset: NFTAsset, in collection: NFTCollection) -> SendCoordinator.Options {
        let sendAvailabilityProvider = TransactionSendAvailabilityProvider(
            isSendingSupportedByCard: userWalletModel.config.hasFeature(.send)
        )
        let tokenItem = makeTokenItem(asset: asset, mainTokenWalletModel: walletModel)
        let tokenBalanceProvider = NFTSendFixedBalanceProvider(tokenItem: tokenItem, fixedValue: amountToSend)
        let walletModelProxy = NFTSendWalletModelProxy(
            asset: asset,
            tokenItem: tokenItem,
            mainTokenWalletModel: walletModel,
            tokenBalanceProvider: tokenBalanceProvider,
            transactionSendAvailabilityProvider: sendAvailabilityProvider
        )

        let parameters = SendParameters(nonFungibleTokenParameters: (asset, collection))

        return SendCoordinator.Options(
            walletModel: walletModelProxy,
            userWalletModel: userWalletModel,
            type: .send(parameters: parameters),
            source: .nft
        )
    }

    private func makeTokenItem(asset: NFTAsset, mainTokenWalletModel: any WalletModel) -> TokenItem {
        let contractType = map(contractType: asset.id.contractType)
        let metadata = TokenMetadata(kind: .nonFungible(assetIdentifier: asset.id.identifier, contractType: contractType))
        let token = Token(
            name: asset.name,
            symbol: asset.name,
            contractAddress: asset.id.contractAddress,
            decimalCount: asset.decimalCount,
            metadata: metadata
        )
        let blockchainNetwork = mainTokenWalletModel.tokenItem.blockchainNetwork

        return .token(token, blockchainNetwork)
    }

    private func map(contractType: NFTContractType) -> TokenMetadata.ContractType {
        switch contractType {
        case .erc1155:
            return .erc1155
        case .erc721:
            return .erc721
        case .other,
             .unknown:
            return .unspecified
        }
    }
}
