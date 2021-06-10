//
//  Blockchain+.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

extension Blockchain: Identifiable {
    public var id: Int { return hashValue }
    
    var imageName: String? {
        switch self {
        case .binance:
            return "binance"
        case .bitcoin:
            return "btc"
        case .bitcoinCash:
            return "btc_cash"
        case .cardano:
            return "cardano"
        case .ethereum:
            return "eth"
        case .litecoin:
            return "litecoin"
        case .rsk:
            return "rsk"
        case .tezos:
            return "tezos"
        case .xrp:
            return "xrp"
        case .stellar:
            return "stellar"
        case .ducatus:
            return nil
        case .dogecoin:
            return nil
        case .bsc:
            return nil
        case .matic:
            return nil
        }
    }
    
    var testnetTopupLink: String? {
        guard isTestnet else { return nil }
        
        switch self {
        case .bitcoin:
            return "https://coinfaucet.eu/en/btc-testnet/"
        case .ethereum:
            return "https://faucet.rinkeby.io"
        case .bitcoinCash:
            // alt
            // return "https://faucet.fullstack.cash"
            return "https://coinfaucet.eu/en/bch-testnet/"
        case .bsc:
            return "https://testnet.binance.org/faucet-smart"
        case .binance:
            return nil
//            return "https://academy.binance.com/en/articles/binance-dex-funding-your-testnet-account"
//            return "https://docs.binance.org/guides/testnet.html"
        case .matic:
            return "https://faucet.matic.network"
        case .stellar:
            return "https://laboratory.stellar.org/#account-creator?network=test"
        default:
            return nil
        }
    }
}
