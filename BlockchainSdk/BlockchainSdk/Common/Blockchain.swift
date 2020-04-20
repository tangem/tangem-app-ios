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
    case rsk
    case bitcoinCash(testnet: Bool)
    case binance(testnet: Bool)
    case cardano
    case xrp(curve: EllipticCurve)
    case ducatus
    
    public var isTestnet: Bool {
        switch self {
        case .bitcoin(let testnet):
            return testnet
        case .litecoin, .ducatus, .cardano, .xrp, .rsk:
            return false
        case .stellar(let testnet):
            return testnet
        case .ethereum(let testnet):
            return testnet
        case .bitcoinCash(let testnet):
            return testnet
        case .binance(let testnet):
            return testnet
        }
    }
    
    public var decimalCount: Int {
        switch self {
        case .bitcoin, .litecoin, .bitcoinCash, .ducatus:
            return 8
        case .ethereum, .rsk:
            return 18
        case  .cardano, .xrp:
            return 6
        case .binance:
            return 8
        case .stellar:
            return 7
        }
    }
    
    public var roundingMode: NSDecimalNumber.RoundingMode {
        switch self {
        case .bitcoin, .litecoin, .ethereum, .rsk, .bitcoinCash, .binance, .ducatus:
            return .down
        case .stellar, .xrp:
            return .plain
        case .cardano:
            return .up
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
        case .binance:
            return "BNB"
        case .ducatus:
            return "DUC"
        case .cardano:
            return "ADA"
        case .xrp:
            return "XRP"
        }
    }
    
    public var displayName: String {
        switch self {
        case .bitcoinCash:
            return "Bitcoin Cash"
        default:
            let name = "\(self)".capitalizingFirstLetter()
            return isTestnet ?  name + " test" : name
        }
    }
    
    public func makeAddress(from walletPublicKey: Data) -> String {
        return getAddressService().makeAddress(from: walletPublicKey)
    }
    
    public func validate(address: String) -> Bool {
        return getAddressService().validate(address)
    }
    
    public func getShareString(from address: String) -> String {
        switch self {
        case .bitcoin:
            return "bitcoin:\(address)"
        case .ethereum(let testnet):
            let sharePrefix = testnet ? "" : "ethereum:"
            return "\(sharePrefix)\(address)"
        case .litecoin:
            return "litecoin:\(address)"
        case .xrp:
            return "ripple:\(address)"
        default:
            return "\(address)"
        }
    }
    
    public func getExploreURL(from address: String, token: Token? = nil) -> URL {
        switch self {
        case .binance:
            return URL(string: "https://explorer.binance.org/address/\(address)")!
        case .bitcoin:
            return URL(string: "https://blockchain.info/address/\(address)")!
        case .bitcoinCash:
            return URL(string: "https://blockchair.com/bitcoin-cash/address/\(address)")!
        case .cardano:
            return URL(string: "https://cardanoexplorer.com/address/\(address)")!
        case .ducatus:
            return URL(string: "https://insight.ducatus.io/#/DUC/mainnet/address/\(address)")!
        case .ethereum(let testnet):
            let baseUrl = testnet ? "https://rinkeby.etherscan.io/address/" : "https://etherscan.io/address/"
            let exploreLink = token == nil ? baseUrl + address :
            "https://etherscan.io/token/\(token!.contractAddress)?a=\(address)"
            return URL(string: exploreLink)!
        case .litecoin:
            return URL(string: "https://live.blockcypher.com/ltc/address/\(address)")!
        case .rsk:
            var exploreLink = "https://explorer.rsk.co/address/\(address)"
            if token != nil {
                exploreLink += "?__tab=tokens"
            }
            return URL(string: exploreLink)!
        case .stellar(let testnet):
            let baseUrl = testnet ? "https://stellar.expert/explorer/testnet/account/" : "https://stellar.expert/explorer/public/account/"
            let exploreLink =  baseUrl + address
            return URL(string: exploreLink)!
        case .xrp:
            return URL(string: "https://xrpscan.com/account/\(address)")!
        }
    }
    
    public static func from(blockchainName: String, curve: EllipticCurve) -> Blockchain? {
        let testnetAttribute = "/test"
        let isTestnet = blockchainName.contains(testnetAttribute)
        let cleanName = blockchainName.remove(testnetAttribute).lowercased()
        switch cleanName {
        case "btc": return .bitcoin(testnet: isTestnet)
        case "xlm", "asset", "xlm-tag": return .stellar(testnet: isTestnet)
        case "eth", "token", "nfttoken": return .ethereum(testnet: isTestnet)
        case "ltc": return .litecoin
        case "rsk", "rsktoken": return .rsk
        case "bch": return .bitcoinCash(testnet: isTestnet)
        case "binance": return .binance(testnet: isTestnet)
        case "cardano": return .cardano
        case "xrp": return .xrp(curve: curve)
        case "duc": return .ducatus
        default: return nil
        }
    }
    
    func getAddressService() -> AddressService {
        switch self {
        case .bitcoin(let testnet):
            return BitcoinAddressService(testnet: testnet)
        case .litecoin:
            return LitecoinAddressService(testnet: false)
        case .stellar:
            return StellarAddressService()
        case .ethereum, .rsk:
            return EthereumAddressService()
        case .bitcoinCash:
            return BitcoinCashAddressService()
        case .binance(let testnet):
            return BinanceAddressService(testnet: testnet)
        case .ducatus:
            return DucatusAddressService(testnet: false)
        case .cardano:
            return CardanoAddressService()
        case .xrp(let curve):
            return XRPAddressService(curve: curve)
        }
    }
}
