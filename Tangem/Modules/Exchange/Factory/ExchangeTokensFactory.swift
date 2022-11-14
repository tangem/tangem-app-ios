//
//  ExchangeTokensFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

class ExchangeTokensFactory {
    enum Token {
        case dai
        case tether
    }

    let coinModel: CoinModel
    let blockchainNetwork: BlockchainNetwork

    init(coinModel: CoinModel, blockchainNetwork: BlockchainNetwork) {
        self.coinModel = coinModel
        self.blockchainNetwork = blockchainNetwork
    }

    func createToken(token: Token) -> Currency {
        switch token {
        case .dai:
            let currency = coinModel
                .items
                .compactMap { token in
                    if token.name.contains("Dai Stablecoin") {
                        return Currency(contractAddress: token.contractName ?? "",
                                        blockchainNetwork: blockchainNetwork,
                                        name: token.name,
                                        symbol: token.symbol,
                                        decimalCount: 18,
                                        imageURL: coinModel.imageURL)
                    } else {
                        return nil
                    }
                }
                .first

            if let currency {
                return currency
            } else {
                return Currency(contractAddress: Constants.oneInchCoinContractAddress,
                                blockchainNetwork: blockchainNetwork,
                                name: coinModel.name,
                                symbol: coinModel.symbol,
                                imageURL: coinModel.imageURL)
            }
        case .tether:
            let currency = coinModel
                .items
                .compactMap { token in
                    if token.name.contains("Tether") {
                        return Currency(contractAddress: token.contractName ?? "",
                                        blockchainNetwork: blockchainNetwork,
                                        name: token.name,
                                        symbol: token.symbol,
                                        decimalCount: 6,
                                        imageURL: coinModel.imageURL)
                    } else {
                        return nil
                    }
                }
                .first
            if let currency {
                return currency
            } else {
                return Currency(contractAddress: Constants.oneInchCoinContractAddress,
                                blockchainNetwork: blockchainNetwork,
                                name: coinModel.name,
                                symbol: coinModel.symbol,
                                imageURL: coinModel.imageURL)
            }
        }
    }

    func createCoin() -> Currency {
        return Currency(contractAddress: Constants.oneInchCoinContractAddress,
                        blockchainNetwork: blockchainNetwork,
                        name: coinModel.name,
                        symbol: coinModel.symbol,
                        decimalCount: 18,
                        imageURL: coinModel.imageURL)
    }
}
