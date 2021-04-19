//
//  Blockchain.swift
//  blockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdkClips
import BitcoinCore

public enum Blockchain {
    case bitcoin(testnet: Bool)
    case litecoin
    case stellar(testnet: Bool)
    case ethereum(testnet: Bool)
    case rsk
    case bitcoinCash(testnet: Bool)
//    case binance(testnet: Bool)
    case cardano(shelley: Bool)
    case xrp(curve: EllipticCurve)
    case ducatus
    case tezos(curve: EllipticCurve)
    
    public var isTestnet: Bool {
        switch self {
        case .bitcoin(let testnet):
            return testnet
        case .litecoin, .ducatus, .cardano, .xrp, .rsk, .tezos:
            return false
        case .stellar(let testnet):
            return testnet
        case .ethereum(let testnet):
            return testnet
        case .bitcoinCash(let testnet):
            return testnet
//        case .binance(let testnet):
//            return testnet
        }
    }
    
    public var curve: EllipticCurve {
        switch self {
        case .cardano, .stellar:
            return .ed25519
        case .xrp(let curve):
            return curve
        case .tezos(let curve):
            return curve
        default:
            return .secp256k1
        }
    }
    
    public var decimalCount: Int {
        switch self {
        case .bitcoin, .litecoin, .bitcoinCash, .ducatus:
//             , .binance:
            return 8
        case .ethereum, .rsk:
            return 18
        case  .cardano, .xrp, .tezos:
            return 6
        case .stellar:
            return 7
        }
    }
    
    public var decimalValue: Decimal {
        return pow(Decimal(10), decimalCount)
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
//        case .binance:
//            return "BNB"
        case .ducatus:
            return "DUC"
        case .cardano:
            return "ADA"
        case .xrp:
            return "XRP"
        case .tezos:
            return "XTZ"
        }
    }
    
    public var displayName: String {
        switch self {
        case .bitcoinCash:
            return "Bitcoin Cash"
        case .xrp:
            return "XRP Ledger"
        case .rsk:
            return "\(self)".uppercased()
        default:
            var name = "\(self)".capitalizingFirstLetter()
            if let index = name.firstIndex(of: "(") {
                name = String(name.prefix(upTo: index))
            }
            return isTestnet ?  name + " test" : name
        }
    }
    
    public var tokenDisplayName: String {
        switch self {
        case .stellar:
            return "Stellar Asset"
        case .ethereum:
            return "Ethereum smart contract token"
//        case .binance:
//            return "Binance Asset"
        default:
            return displayName
        }
    }
    
    public var qrPrefixes: [String] {
        switch self {
        case .bitcoin:
            return ["bitcoin:"]
        case .ethereum(let testnet):
            return [testnet ? "" : "ethereum:"]
        case .litecoin:
            return ["litecoin:"]
        case .xrp:
            return ["xrpl:", "ripple:"]
//        case .binance:
//            return ["bnb:"]
        default:
            return [""]
        }
    }
    
    public var defaultAddressType: AddressType {
        switch self {
        case .bitcoin: return .bitcoin(type: .bech32)
        default: return .plain
        }
    }
    
    public func makeAddresses(from walletPublicKey: Data, with pairPublicKey: Data?) -> [Address] {
        let addressService = getAddressService()
        if let multiSigAddressProvider = addressService as? MultisigAddressProvider,
           let pairKey = pairPublicKey,
           let addresses = multiSigAddressProvider.makeAddresses(from: walletPublicKey, with: pairKey) {
            return addresses
        }
        
        return addressService.makeAddresses(from: walletPublicKey)
    }
    
    public func validate(address: String) -> Bool {
        getAddressService().validate(address)
    }
    
    public func getShareString(from address: String) -> String {
        switch self {
        case .bitcoin, .ethereum, .litecoin, .xrp:
            return "\(qrPrefixes.first ?? "")\(address)"
        default:
            return "\(address)"
        }
    }
    
    public func getExploreURL(from address: String, tokenContractAddress: String? = nil) -> URL? {
        switch self {
//        case .binance:
//            return URL(string: "https://explorer.binance.org/address/\(address)")
        case .bitcoin:
            return URL(string: "https://blockchain.info/address/\(address)")
        case .bitcoinCash:
            return URL(string: "https://blockchair.com/bitcoin-cash/address/\(address)")
        case .cardano:
            return URL(string: "https://cardanoexplorer.com/address/\(address)")
        case .ducatus:
            return URL(string: "https://insight.ducatus.io/#/DUC/mainnet/address/\(address)")
        case .ethereum(let testnet):
            let baseUrl = testnet ? "https://rinkeby.etherscan.io/address/" : "https://etherscan.io/address/"
            let exploreLink = tokenContractAddress == nil ? baseUrl + address :
                "https://etherscan.io/token/\(tokenContractAddress!)?a=\(address)"
            return URL(string: exploreLink)
        case .litecoin:
            return URL(string: "https://live.blockcypher.com/ltc/address/\(address)")
        case .rsk:
            var exploreLink = "https://explorer.rsk.co/address/\(address)"
            if tokenContractAddress != nil {
                exploreLink += "?__tab=tokens"
            }
            return URL(string: exploreLink)
        case .stellar(let testnet):
            let baseUrl = testnet ? "https://stellar.expert/explorer/testnet/account/" : "https://stellar.expert/explorer/public/account/"
            let exploreLink =  baseUrl + address
            return URL(string: exploreLink)
        case .xrp:
            return URL(string: "https://xrpscan.com/account/\(address)")
        case .tezos:
            return URL(string: "https://tezblock.io/account/\(address)")
        }
    }
    
    public static func from(blockchainName: String, curve: EllipticCurve) -> Blockchain? {
        let testnetAttribute = "/test"
        let isTestnet = blockchainName.contains(testnetAttribute)
        let cleanName = blockchainName.remove(testnetAttribute).lowercased()
        switch cleanName {
        case "btc": return .bitcoin(testnet: isTestnet)
//        case "xlm", "asset", "xlm-tag": return .stellar(testnet: isTestnet)
        case "eth", "token", "nfttoken": return .ethereum(testnet: isTestnet)
        case "ltc": return .litecoin
        case "rsk", "rsktoken": return .rsk
        case "bch": return .bitcoinCash(testnet: isTestnet)
//        case "binance", "binanceasset": return .binance(testnet: isTestnet)
        case "cardano": return .cardano(shelley: false)
        case "cardano-s": return .cardano(shelley: true)
        case "xrp": return .xrp(curve: curve)
        case "duc": return .ducatus
//        case "xtz": return .tezos(curve: curve)
        default: return nil
        }
    }
    
    func getAddressService() -> AddressService {
        switch self {
        case .bitcoin(let testnet):
            let network: BitcoinNetwork = testnet ? .testnet : .mainnet
            let networkParams = network.networkParams
            return BitcoinAddressService(networkParams: networkParams)
        case .litecoin:
            return BitcoinLegacyAddressService(networkParams: LitecoinNetworkParams())
        case .stellar:
            return StellarAddressService()
        case .ethereum, .rsk:
            return EthereumAddressService()
        case .bitcoinCash:
            return BitcoinCashAddressService()
//        case .binance(let testnet):
//            return BinanceAddressService(testnet: testnet)
        case .ducatus:
            return BitcoinLegacyAddressService(networkParams: DucatusNetworkParams())
        case .cardano(let shelley):
            return CardanoAddressService(shelley: shelley)
        case .xrp(let curve):
            return XRPAddressService(curve: curve)
        case .tezos:
            return TezosAddressService()
        }
    }
}


extension Blockchain: Equatable, Hashable, Codable {
    var codingKey: String {
        switch self {
//        case .binance: return "binance"
        case .bitcoin: return "bitcoin"
        case .bitcoinCash: return "bitcoinCash"
        case .cardano: return "cardano"
        case .ducatus: return "ducatus"
        case .ethereum: return "ethereum"
        case .litecoin: return "litecoin"
        case .rsk: return "rsk"
        case .stellar: return "stellar"
        case .tezos: return "tezos"
        case .xrp: return "xrp"
        }
    }
    
    enum Keys: CodingKey {
        case key
        case testnet
        case curve
        case shelley
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        let key = try container.decode(String.self, forKey: Keys.key)
        let curveString = try container.decode(String.self, forKey: Keys.curve)
        let isTestnet = try container.decode(Bool.self, forKey: Keys.testnet)
        let shelley = try? container.decode(Bool.self, forKey: Keys.shelley)
        
        guard let curve = EllipticCurve(rawValue: curveString) else {
            throw BlockchainSdkError.decodingFailed
        }
        
        switch key {
        case "bitcoin": self = .bitcoin(testnet: isTestnet)
        case "stellar": self = .stellar(testnet: isTestnet)
        case "ethereum": self = .ethereum(testnet: isTestnet)
        case "litecoin": self = .litecoin
        case "rsk": self = .rsk
        case "bitcoinCash": self = .bitcoinCash(testnet: isTestnet)
//        case "binance": self = .binance(testnet: isTestnet)
        case "cardano": self =  .cardano(shelley: shelley!)
        case "xrp": self = .xrp(curve: curve)
        case "ducatus": self = .ducatus
        case "tezos": self = .tezos(curve: curve)
        default: throw BlockchainSdkError.decodingFailed
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)
        try container.encode(codingKey, forKey: Keys.key)
        try container.encode(curve.rawValue, forKey: Keys.curve)
        try container.encode(isTestnet, forKey: Keys.testnet)
        
        if case let .cardano(shelley) = self {
            try container.encode(shelley, forKey: Keys.shelley)
        }
    }
}
