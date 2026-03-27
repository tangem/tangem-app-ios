//
//  WalletTokenAutoSyncRelayer.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemSdk

protocol WalletTokenAutoSyncRelayer {
    func resolveTokenStream(
        blockchain: Blockchain,
        keyInfos: [KeyInfo]
    ) async throws -> AsyncThrowingStream<TokenItem, Error>
}

extension WalletTokenAutoSyncRelayer {
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
