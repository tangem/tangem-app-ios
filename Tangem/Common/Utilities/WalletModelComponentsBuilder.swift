//
//  WalletModelComponentsBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import enum BlockchainSdk.Blockchain
import struct BlockchainSdk.Amount

// [REDACTED_TODO_COMMENT]
struct WalletModelComponentsBuilder {
    typealias UserToken = StorageEntry.V3.Entry

    private let supportedBlockchains: Set<Blockchain>

    init(
        supportedBlockchains: Set<Blockchain>
    ) {
        self.supportedBlockchains = supportedBlockchains
    }

    func buildBlockchainNetwork(from token: UserToken) -> BlockchainNetwork? {
        let blockchainNetwork = token.blockchainNetwork

        guard let blockchain = supportedBlockchains[blockchainNetwork.blockchain.networkId] else { return nil }

        return BlockchainNetwork(blockchain, derivationPath: blockchainNetwork.derivationPath)
    }

    func buildWalletModelID(from token: UserToken) -> WalletModel.ID? {
        guard let blockchainNetwork = buildBlockchainNetwork(from: token) else { return nil }

        let amountType = amountType(from: token)

        return WalletModel.Id(blockchainNetwork: blockchainNetwork, amountType: amountType).id
    }

    private func amountType(from token: UserToken) -> Amount.AmountType {
        if let contractAddress = token.contractAddress {
            return .token(
                value: .init(
                    name: token.name,
                    symbol: token.symbol,
                    contractAddress: contractAddress,
                    decimalCount: token.decimalCount,
                    id: token.id
                )
            )
        } else {
            return .coin
        }
    }
}
