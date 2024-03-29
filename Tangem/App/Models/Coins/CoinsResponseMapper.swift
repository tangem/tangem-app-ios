//
//  CoinsResponseMapper.swift
//  Tangem
//
//  Created by Sergey Balashov on 08.08.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct CoinsResponseMapper {
    let supportedBlockchains: Set<Blockchain>

    init(supportedBlockchains: Set<Blockchain>) {
        self.supportedBlockchains = supportedBlockchains
    }

    func mapToCoinModels(_ response: CoinsList.Response) -> [CoinModel] {
        response.coins.compactMap { coin in
            let id = coin.id.trimmed()
            let name = coin.name.trimmed()
            let symbol = coin.symbol.uppercased().trimmed()

            let items: [CoinModel.Item] = coin.networks.compactMap { network in
                guard let item = mapToTokenItem(id: id, name: name, symbol: symbol, network: network) else {
                    return nil
                }

                return CoinModel.Item(id: id, tokenItem: item, exchangeable: network.exchangeable)
            }

            if items.isEmpty {
                return nil
            }

            return CoinModel(id: id, name: name, symbol: symbol, items: items)
        }
    }

    private func mapToTokenItem(id: String, name: String, symbol: String, network: CoinsList.Network) -> TokenItem? {
        // We should find and use a exactly same blockchain that in the supportedBlockchains set
        guard let blockchain = supportedBlockchains[network.networkId] else {
            return nil
        }

        guard let contractAddress = network.contractAddress,
              let decimalCount = network.decimalCount else {
            return .blockchain(.init(blockchain, derivationPath: nil))
        }

        guard blockchain.canHandleTokens else {
            return nil
        }

        let token = Token(
            name: name,
            symbol: symbol,
            contractAddress: contractAddress.trimmed(),
            decimalCount: decimalCount,
            id: id
        )

        return .token(token, .init(blockchain, derivationPath: nil))
    }
}
