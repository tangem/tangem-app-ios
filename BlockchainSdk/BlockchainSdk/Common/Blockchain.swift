//
//  Blockchain.swift
//  blockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

public enum Blockchain {
    case bitcoin(testnet: Bool)
    case litecoin
    case stellar(testnet: Bool)
    case ethereum(testnet: Bool)
    case rsk(testnet: Bool)
    case bitcoinCash(testnet: Bool)
    //    case cardano
    //    case ripple
    //    case binance
    //    case stellar
    //case ducatus
    //case tezos
    
    public var isTestnet: Bool {
        switch self {
        case .bitcoin(let testnet):
            return testnet
        case .litecoin:
            return false
        case .stellar(let testnet):
            return testnet
        case .ethereum(let testnet):
            return testnet
        case .rsk(let testnet):
            return testnet
        case .bitcoinCash(let testnet):
            return testnet
        }
    }
    
    public var decimalCount: Int {
        switch self {
        case .bitcoin, .litecoin, .bitcoinCash:
            return 8
        case .ethereum, .rsk:
            return 18
            //        case .ripple, .cardano:
            //            return 6
            //        case .binance:
        //            return 8
        case .stellar:
            return 7
        }
    }
    
    public var roundingMode: NSDecimalNumber.RoundingMode {
        switch self {
        case .bitcoin, .litecoin, .ethereum, .rsk, .bitcoinCash://, .binance:
            return .down
        case .stellar:
            return .plain
            //        case .cardano:
            //            return .up
        }
    }
    public var currencySymbol: String {
        switch self {
        case .bitcoin:
            return "BTC"
        case .litecoin:
            return "LTC"
        case .stellar:
            return "XLM"
        case .ethereum:
            return "ETH"
        case .rsk:
            return "RBTC"
        case .bitcoinCash:
            return "BCH"
        }
    }
    
    public func makeAddress(from walletPublicKey: Data) -> String {
        switch self {
        case .bitcoin(let testnet):
            return BitcoinAddressFactory().makeAddress(from: walletPublicKey, testnet: testnet)
        case .litecoin:
            return LitecoinAddressFactory().makeAddress(from: walletPublicKey, testnet: false)
        case .stellar:
            return StellarAddressFactory().makeAddress(from: walletPublicKey)
        case .ethereum, .rsk:
            return EthereumAddressFactory().makeAddress(from: walletPublicKey)
        case .bitcoinCash:
            let compressedKey = CryptoUtils.convertKeyToCompressed(walletPublicKey)!
            return BitcoinCashAddressFactory().makeAddress(from: compressedKey)
        }
    }
    
    public func validate(address: String) -> Bool {
        switch self {
        case .bitcoin(let testnet):
            return BitcoinAddressValidator().validate(address, testnet: testnet)
        case .litecoin:
            return LitecoinAddressValidator().validate(address, testnet: false)
        case .stellar:
            return StellarAddressValidator().validate(address)
        case .ethereum, .rsk:
            return EthereumAddressValidator().validate(address)
        case .bitcoinCash:
            return BitcoinCashAddressValidator().validate(address)
        }
    }
    
    public static func from(blockchainName: String) -> Blockchain? {
        let testnetAttribute = "/test"
        let isTestnet = blockchainName.contains(testnetAttribute)
        let cleanName = blockchainName.remove(testnetAttribute).lowercased()
        switch cleanName {
        case "btc": return .bitcoin(testnet: isTestnet)
        case "xlm", "asset", "xlm-tag": return .stellar(testnet: isTestnet)
        case "eth", "token", "nfttoken": return .ethereum(testnet: isTestnet)
        case "ltc": return .litecoin
        case "rsk", "rsktoken": return .rsk(testnet: isTestnet)
        case "bch": return .bitcoinCash(testnet: isTestnet)
            //case "cardano": return .cardano
            //case "xrp": return .ripple
            //case "binance": return .binance
            //case "duc": return .ducatus
            //case "tezos": return .tezos
        default: return nil
        }
    }
}
