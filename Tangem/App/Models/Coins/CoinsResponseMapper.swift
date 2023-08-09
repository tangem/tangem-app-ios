//
//  CoinsResponseMapper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct CoinsResponseMapper {
    let supportedBlockchains: Set<Blockchain>

    init(supportedBlockchains: Set<Blockchain>) {
        self.supportedBlockchains = supportedBlockchains
    }

    func mapToToken(contract: String, in response: CoinsList.Response) -> Token? {
        let coinModels = mapToCoinModels(response)
        var token: Token?

        for coinModel in coinModels {
            for tokenItem in coinModel.items {
                if tokenItem.contractAddress?.caseInsensitiveCompare(contract) == .orderedSame {
                    token = tokenItem.token
                    break
                }
            }
        }

        return token
    }

    func mapToCoinModels(_ response: CoinsList.Response) -> [CoinModel] {
        response.coins.map { coin in
            let id = coin.id.trimmed()
            let name = coin.name.trimmed()
            let symbol = coin.symbol.uppercased().trimmed()
            var imageURL: URL?

            if let imageHost = response.imageHost {
                imageURL = imageHost
                    .appendingPathComponent(TokenURLIconSize.large.rawValue)
                    .appendingPathComponent("\(id).png")
            }

            let items: [TokenItem] = coin.networks.compactMap { network in
                // We should find and use a exactly same blockchain that in the supportedBlockchains set
                guard let blockchain = supportedBlockchains.first(where: { $0.networkId == network.networkId }) else {
                    return nil
                }

                guard let contractAddress = network.contractAddress,
                      let decimalCount = network.decimalCount else {
                    return .blockchain(blockchain)
                }

                let token = Token(
                    name: name,
                    symbol: symbol,
                    contractAddress: contractAddress.trimmed(),
                    decimalCount: decimalCount,
                    id: id,
                    exchangeable: network.exchangeable
                )

                return .token(token, blockchain)
            }

            return CoinModel(id: id, name: name, symbol: symbol, imageURL: imageURL, items: items)
        }
    }
}
