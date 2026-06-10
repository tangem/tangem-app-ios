//
//  WalletAssetsDiscoveryRelayer.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemSdk

protocol WalletAssetsDiscoveryRelayer {
    func resolveTokenStream(
        pair: NetworkAddressPair,
        keyInfos: [KeyInfo]
    ) async throws -> AsyncThrowingStream<TokenItem, Error>
}

extension WalletAssetsDiscoveryRelayer {
    func makeTokenItem(
        contract: CoinsList.Coin,
        blockchainNetwork: BlockchainNetwork
    ) -> TokenItem? {
        guard
            let network = contract.networks.first(where: { $0.networkId == blockchainNetwork.blockchain.networkId }),
            let contractAddress = network.contractAddress,
            let decimalCount = network.decimalCount
        else {
            return nil
        }

        let token = Token(
            name: contract.name,
            symbol: contract.symbol,
            contractAddress: contractAddress,
            decimalCount: decimalCount,
            id: contract.id
        )

        return .token(token, blockchainNetwork)
    }
}
