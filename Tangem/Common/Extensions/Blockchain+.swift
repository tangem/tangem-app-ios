//
//  Blockchain+.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
#if !CLIP
import BlockchainSdk
#endif

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
        case .polygon:
            return nil
        case .avalanche:
            return nil
        case .solana:
            return nil
        }
    }
    
    var testnetBuyCryptoLink: String? {
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
            return "https://docs.binance.org/smart-chain/wallet/binance.html"
//            return "https://docs.binance.org/guides/testnet.html"
        case .polygon:
            return "https://faucet.matic.network"
        case .stellar:
            return "https://laboratory.stellar.org/#account-creator?network=test"
        case .solana:
            return "https://solfaucet.com"
        default:
            return nil
        }
    }
}
