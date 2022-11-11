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
        case dai(blockchain: BlockchainNetwork)
        case tether(blockchain: BlockchainNetwork)
    }

    func createToken(token: Token) -> ExchangeCurrency {
        switch token {
        case let .dai(blockchainNetwork):
            var name = "Dai Stablecoin"
            var symbol = "DAI"
            let decimalCount: Decimal = 18
            let contractAddress: String
            switch blockchainNetwork.blockchain {
            case .bsc:
                contractAddress = "0x1af3f329e8be154074d8769d1ffa4ee058b1dbc3"
            case .ethereum:
                contractAddress = "0x6b175474e89094c44da98b954eedeac495271d0f"
            case .avalanche:
                symbol = "DAI.e"
                contractAddress = "0xd586e7f844cea2f87f50152665bcbc2c279d8d70"
            case .optimism:
                contractAddress = "0xda10009cbd5d07dd0cecc66161fc93d7c9000da1"
            case .polygon:
                contractAddress = "0x8f3cf7ad23cd3cadbd9735aff958023239c6a063"
            case .arbitrum:
                contractAddress = "0xda10009cbd5d07dd0cecc66161fc93d7c9000da1"
            case .gnosis:
                name = "Dai Stablecoin from Ethereum"
                contractAddress = "0x44fa8e6f47987339850636f88629646662444217"
            case .fantom:
                contractAddress = "0x8d11ec38a3eb5e956b052f67da8bdc9bef8abf3e"
            default:
                return ExchangeCurrency(type: .coin(BlockchainNetwork(.ethereum(testnet: false))))
            }

            return ExchangeCurrency(type: .token(blockchainNetwork, contractAddress: contractAddress),
                                    name: name,
                                    symbol: symbol,
                                    decimalCount: decimalCount)

        case let .tether(blockchainNetwork):
            var name = "Tether USD"
            var symbol = "USDT"
            let decimalCount: Decimal = 6
            let contractAddress: String
            switch blockchainNetwork.blockchain {
            case .bsc:
                contractAddress = "0x55d398326f99059ff775485246999027b3197955"
            case .ethereum:
                contractAddress = "0xdac17f958d2ee523a2206206994597c13d831ec7"
            case .avalanche:
                symbol = "USDT.e"
                contractAddress = "0xd586e7f844cea2f87f50152665bcbc2c279d8d70"
            case .optimism:
                contractAddress = "0x94b008aa00579c1307b0ef2c499ad98a8ce58e58"
            case .polygon:
                contractAddress = "0xc2132d05d31c914a87c6611c10748aeb04b58e8f"
            case .arbitrum:
                contractAddress = "0xfd086bc7cd5c481dcc9c85ebe478a1c0b69fcbb9"
            case .gnosis:
                name = "Tether on xDai"
                contractAddress = "0x4ecaba5870353805a9f068101a40e0f32ed605c6"
            default:
                return ExchangeCurrency(type: .coin(BlockchainNetwork(.ethereum(testnet: false))))
            }

            return ExchangeCurrency(type: .token(blockchainNetwork, contractAddress: contractAddress),
                                    name: name,
                                    symbol: symbol,
                                    decimalCount: decimalCount)
        }
    }

    func createCoin(for blockchainNetwork: BlockchainNetwork) -> ExchangeCurrency {
        let name: String
        let symbol: String
        let decimalCount: Decimal

        switch blockchainNetwork.blockchain {
        case .bsc:
            name = "BNB"
            symbol = "BNB"
            decimalCount = 18
        case .ethereum:
            name = "Ethereum"
            symbol = "ETH"
            decimalCount = 18
        case .avalanche:
            name = "Avalanche"
            symbol = "AVAX"
            decimalCount = 18
        case .optimism:
            name = "Ethereum"
            symbol = "ETH"
            decimalCount = 18
        case .polygon:
            name = "MATIC"
            symbol = "MATIC"
            decimalCount = 18
        case .arbitrum:
            name = "Ethereum"
            symbol = "ETH"
            decimalCount = 18
        case .gnosis:
            name = "xDAI"
            symbol = "xDAI"
            decimalCount = 18
        case .fantom:
            name = "Fantom Token"
            symbol = "FTM"
            decimalCount = 18
        default:
            return ExchangeCurrency(type: .coin(BlockchainNetwork(.ethereum(testnet: false))),
                                    name: "Ethereum",
                                    symbol: "ETH",
                                    decimalCount: 18)
        }
        return ExchangeCurrency(type: .coin(blockchainNetwork),
                                name: name,
                                symbol: symbol,
                                decimalCount: decimalCount)
    }
}
