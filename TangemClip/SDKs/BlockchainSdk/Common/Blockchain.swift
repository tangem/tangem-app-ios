//
//  Blockchain.swift
//  blockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

// MARK: - Base
@available(iOS 13.0, *)
public enum Blockchain: Equatable, Hashable {
    case bitcoin(testnet: Bool)
    case litecoin
    case stellar(testnet: Bool)
    case ethereum(testnet: Bool)
    case rsk
    case bitcoinCash(testnet: Bool)
    case binance(testnet: Bool)
    case cardano(shelley: Bool)
    case xrp(curve: EllipticCurve)
    case ducatus
    case tezos(curve: EllipticCurve)
    case dogecoin
    case bsc(testnet: Bool)
    case polygon(testnet: Bool)
    case avalanche(testnet: Bool)
    case solana(testnet: Bool)
    case fantom(testnet: Bool)
    case polkadot(testnet: Bool)
    case kusama

    public var isTestnet: Bool {
        switch self {
        case .bitcoin(let testnet):
            return testnet
        case .litecoin, .ducatus, .cardano, .xrp, .rsk, .tezos, .dogecoin, .kusama:
            return false
        case .stellar(let testnet):
            return testnet
        case .ethereum(let testnet), .bsc(let testnet):
            return testnet
        case .bitcoinCash(let testnet):
            return testnet
        case .binance(let testnet):
            return testnet
        case .polygon(let testnet):
            return testnet
        case .avalanche(let testnet):
            return testnet
        case .solana(let testnet):
            return testnet
        case .fantom(let testnet):
            return testnet
        case .polkadot(let testnet):
            return testnet
        }
    }
    
    public var curve: EllipticCurve {
        switch self {
        case .stellar, .cardano, .solana, .polkadot, .kusama:
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
        case .bitcoin, .litecoin, .bitcoinCash, .ducatus, .binance, .dogecoin:
            return 8
        case .ethereum, .rsk, .bsc, .polygon, .avalanche, .fantom:
            return 18
        case  .cardano, .xrp, .tezos:
            return 6
        case .stellar:
            return 7
        case .solana:
            return 9
        case .polkadot(let testnet):
            return testnet ? 12 : 10
        case .kusama:
            return 12
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
        case .tezos:
            return "XTZ"
        case .dogecoin:
            return "DOGE"
        case .bsc:
            return "BNB"
        case .polygon:
            return "MATIC"
        case .avalanche:
            return "AVAX"
        case .solana:
            return "SOL"
        case .fantom:
            return "FTM"
        case .polkadot(let testnet):
            return testnet ? "WND" : "DOT"
        case .kusama:
            return "KSM"
        }
    }
    
    public var displayName: String {
        let testnetSuffix = isTestnet ? " Testnet" : ""
        
        switch self {
        case .bitcoinCash:
            return "Bitcoin Cash" + testnetSuffix
        case .xrp:
            return "XRP Ledger"
        case .rsk:
            return "\(self)".uppercased()
        case .bsc:
            return "Binance Smart Chain" + testnetSuffix
        case .avalanche:
            return "Avalanche C-Chain" + testnetSuffix
        case .fantom:
            return isTestnet ? "Fantom" + testnetSuffix : "Fantom Opera"
        case .polkadot:
            return "Polkadot" + testnetSuffix + (isTestnet ? " (Westend)" : "")
        default:
            var name = "\(self)".capitalizingFirstLetter()
            if let index = name.firstIndex(of: "(") {
                name = String(name.prefix(upTo: index))
            }
            return name + testnetSuffix
        }
    }
    
    public var tokenDisplayName: String {
        switch self {
        case .stellar:
            return "Stellar Asset"
        case .ethereum:
            return "Ethereum smart contract token"
        case .binance:
            return "Binance Asset"
        case .bsc:
            return "Binance Smart Chain token"
        default:
            return "\(displayName) token"
        }
    }
}

// MARK: - Ethereum based blockchain definition
@available(iOS 13.0, *)
extension Blockchain {
    //Only fot Ethereum compatible blockchains
    public var chainId: Int? {
        switch self {
        case .ethereum: return isTestnet ? 4 : 1
        case .rsk: return 30
        case .bsc: return isTestnet ? 97 : 56
        case .polygon: return isTestnet ? 80001 : 137
        case .avalanche: return isTestnet ? 43113 : 43114
        case .fantom: return isTestnet ? 4002 : 250
        default: return nil
        }
    }
    
    //Only fot Ethereum compatible blockchains
    public func getJsonRpcURLs(infuraProjectId: String?) -> [URL]? {
        switch self {
        case .ethereum:
            guard let infuraProjectId = infuraProjectId else {
                fatalError("infuraProjectId missing")
            }
            
            return isTestnet ? [URL(string:"https://rinkeby.infura.io/v3/\(infuraProjectId)")!]
            : [URL(string: "https://mainnet.infura.io/v3/\(infuraProjectId)")!,
               URL(string: "https://eth.tangem.com/")!]
        case .rsk:
            return [URL(string: "https://public-node.rsk.co/")!]
        case .bsc:
            return isTestnet ? [URL(string: "https://data-seed-prebsc-1-s1.binance.org:8545/")!]
            : [URL(string: "https://bsc-dataseed.binance.org/")!]
        case .polygon:
            return isTestnet ? [URL(string: "https://rpc-mumbai.maticvigil.com/")!]
            : [URL(string: "https://rpc-mainnet.maticvigil.com/")!]
        case .avalanche:
            return isTestnet ? [URL(string: "https://api.avax-test.network/ext/bc/C/rpc")!]
            : [URL(string: "https://api.avax.network/ext/bc/C/rpc")!]
        case .fantom:
            return isTestnet ? [URL(string: "https://rpc.testnet.fantom.network/")!]
            : [URL(string: "https://rpc.ftm.tools/")!,
               URL(string: "https://rpcapi.fantom.network/")!,
               URL(string: "http://rpc.ankr.tools/ftm")!,
               URL(string: "https://ftmrpc.ultimatenodes.io/")!]
        default:
            return nil
        }
    }
}

// MARK: - Address creation
@available(iOS 13.0, *)
extension Blockchain {
    public var defaultAddressType: AddressType {
        switch self {
        case .bitcoin, .litecoin: return .bitcoin(type: .bech32)
        default: return .plain
        }
    }
    
    public var derivationPath: DerivationPath? {
        guard curve == .secp256k1 || curve == .ed25519 else { return  nil }
        
        switch self {
        case .stellar, .solana:
            //Path according to sep-0005. https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0005.md
            // Solana path consistent with TrustWallet:
            // https://github.com/trustwallet/wallet-core/blob/456f22d6a8ce8a66ccc73e3b42bcfec5a6afe53a/registry.json#L1013
            return DerivationPath(nodes: [.hardened(BIP44.purpose),
                                          .hardened(coinType),
                                          .hardened(0)])
        case .cardano(let shelley):
            if !shelley { //We use shelley for all new cards with HD wallets feature
                return nil
            }
            
            //Path according to CIP-1852. https://cips.cardano.org/cips/cip1852/
            return DerivationPath(nodes: [.hardened(1852), //purpose
                                          .hardened(coinType),
                                          .hardened(0),
                                          .nonHardened(0),
                                          .nonHardened(0)])
        default:
            //Standart bip44
            let bip44 = BIP44(coinType: coinType,
                              account: 0,
                              change: .external,
                              addressIndex: 0)
            
            return bip44.buildPath()
        }
    }
    
    // https://github.com/satoshilabs/slips/blob/master/slip-0044.md
    public var coinType: UInt32 {
        if isTestnet {
            return 1
        }
        
        switch self {
        case .bitcoin, .ducatus: return 0
        case .litecoin: return 2
        case .dogecoin: return 3
        case .ethereum: return 60
        case .bsc: return 9006
        case .bitcoinCash: return 145
        case .binance: return 714
        case .xrp: return 144
        case .tezos: return 1729
        case .stellar: return 148
        case .cardano: return 1815
        case .rsk: return 137
        case .polygon: return 966
        case .avalanche: return 9000
        case .solana: return 501
        case .fantom: return 1007
        case .polkadot: return 354
        case .kusama: return 434
        }
    }
    
    public func makeAddresses(from walletPublicKey: Data, with pairPublicKey: Data?) throws -> [Address] {
        let addressService = getAddressService()
        if let multiSigAddressProvider = addressService as? MultisigAddressProvider,
           let pairKey = pairPublicKey {
            return try multiSigAddressProvider.makeAddresses(from: walletPublicKey, with: pairKey)
        }
     
        return try addressService.makeAddresses(from: walletPublicKey)
    }
    
    public func validate(address: String) -> Bool {
        getAddressService().validate(address)
    }
    
    func getAddressService() -> AddressService {
        switch self {
        case .bitcoin:
            let network: BitcoinNetwork = isTestnet ? .testnet : .mainnet
            let networkParams = network.networkParams
            return BitcoinAddressService(networkParams: networkParams)
        case .litecoin:
            return BitcoinAddressService(networkParams: LitecoinNetworkParams())
        case .stellar:
            return StellarAddressService()
        case .ethereum, .bsc, .polygon, .avalanche, .fantom:
            return EthereumAddressService()
        case .rsk:
            return RskAddressService()
        case .bitcoinCash:
            return BitcoinCashAddressService()
        case .binance:
            return BinanceAddressService(testnet: isTestnet)
        case .ducatus:
            return BitcoinLegacyAddressService(networkParams: DucatusNetworkParams())
        case .cardano(let shelley):
            return CardanoAddressService(shelley: shelley)
        case .xrp(let curve):
            return XRPAddressService(curve: curve)
        case .tezos(let curve):
            return TezosAddressService(curve: curve)
        case .dogecoin:
            return BitcoinLegacyAddressService(networkParams: DogecoinNetworkParams())
        case .solana, .polkadot, .kusama:
            fatalError("not implemented")
        }
    }
}

// MARK: - Sharing options
@available(iOS 13.0, *)
extension Blockchain {
    public var qrPrefixes: [String] {
        switch self {
        case .bitcoin:
            return ["bitcoin:"]
        case .ethereum:
            return [isTestnet ? "" : "ethereum:"]
        case .litecoin:
            return ["litecoin:"]
        case .xrp:
            return ["xrpl:", "ripple:", "xrp:"]
        case .binance:
            return ["bnb:"]
        case .dogecoin:
            return ["doge:", "dogecoin:"]
        default:
            return [""]
        }
    }
    
    public func getShareString(from address: String) -> String {
        switch self {
        case .bitcoin, .ethereum, .litecoin, .binance:
            return "\(qrPrefixes.first ?? "")\(address)"
        default:
            return "\(address)"
        }
    }
}

// MARK: - Codable
@available(iOS 13.0, *)
extension Blockchain: Codable {
    public var codingKey: String {
        switch self {
        case .binance: return "binance"
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
        case .dogecoin: return "dogecoin"
        case .bsc: return "bsc"
        case .polygon: return "polygon"
        case .avalanche: return "avalanche"
        case .solana: return "solana"
        case .fantom: return "fantom"
        case .polkadot: return "polkadot"
        case .kusama: return "kusama"
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
        case "binance": self = .binance(testnet: isTestnet)
        case "cardano": self =  .cardano(shelley: shelley!)
        case "xrp": self = .xrp(curve: curve)
        case "ducatus": self = .ducatus
        case "tezos": self = .tezos(curve: curve)
        case "dogecoin": self = .dogecoin
        case "bsc": self = .bsc(testnet: isTestnet)
        case "polygon", "matic": self = .polygon(testnet: isTestnet)
        case "avalanche": self = .avalanche(testnet: isTestnet)
        case "solana": self = .solana(testnet: isTestnet)
        case "fantom": self = .fantom(testnet: isTestnet)
        case "polkadot": self = .polkadot(testnet: isTestnet)
        case "kusama": self = .kusama
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

// MARK: - URLs
@available(iOS 13.0, *)
extension Blockchain {
    public var testnetFaucetURL: URL? {
        guard isTestnet else { return nil }
        
        switch self {
        case .bitcoin:
            return URL(string: "https://coinfaucet.eu/en/btc-testnet/")
        case .ethereum:
            return URL(string: "https://faucet.rinkeby.io")
        case .bitcoinCash:
            // alt
            // return URL(string: "https://faucet.fullstack.cash")
            return URL(string: "https://coinfaucet.eu/en/bch-testnet/")
        case .bsc:
            return URL(string: "https://testnet.binance.org/faucet-smart")
        case .binance:
            return URL(string: "https://docs.binance.org/smart-chain/wallet/binance.html")
//            return URL(string: "https://docs.binance.org/guides/testnet.html")
        case .polygon:
            return URL(string: "https://faucet.matic.network")
        case .stellar:
            return URL(string: "https://laboratory.stellar.org/#account-creator?network=test")
        case .solana:
            return URL(string: "https://solfaucet.com")
        case .avalanche:
            return URL(string: "https://faucet.avax-test.network/")
        case .fantom:
            return URL(string: "https://faucet.fantom.network")
        case .polkadot:
            return URL(string: "https://matrix.to/#/!cJFtAIkwxuofiSYkPN:matrix.org?via=matrix.org&via=matrix.parity.io&via=web3.foundation")
        default:
            return nil
        }
    }
    
    public func getExploreURL(from address: String, tokenContractAddress: String? = nil) -> URL? {
        switch self {
        case .binance:
            let baseUrl = isTestnet ? "https://testnet-explorer.binance.org/address/" : "https://explorer.binance.org/address/"
            return URL(string: baseUrl + address)
        case .bitcoin:
            let baseUrl = isTestnet ? "https://www.blockchain.com/btc-testnet/address/" : "https://www.blockchain.com/btc/address/"
            return URL(string: baseUrl + address)
        case .bitcoinCash:
            let baseUrl = isTestnet ? "https://www.blockchain.com/bch-testnet/address/" : "https://www.blockchain.com/bch/address/"
            return URL(string: baseUrl + address)
        case .cardano:
            return URL(string: "https://explorer.cardano.org/en/address.html?address=\(address)")
        case .ducatus:
            return URL(string: "https://insight.ducatus.io/#/DUC/mainnet/address/\(address)")
        case .ethereum:
            let baseUrl = isTestnet ? "https://rinkeby.etherscan.io/address/" : "https://etherscan.io/address/"
            let exploreLink = tokenContractAddress == nil ? baseUrl + address :
            "https://etherscan.io/token/\(tokenContractAddress!)?a=\(address)"
            return URL(string: exploreLink)
        case .litecoin:
            return URL(string: "https://blockchair.com/litecoin/address/\(address)")
        case .rsk:
            var exploreLink = "https://explorer.rsk.co/address/\(address)"
            if tokenContractAddress != nil {
                exploreLink += "?__tab=tokens"
            }
            return URL(string: exploreLink)
        case .stellar:
            let baseUrl = isTestnet ? "https://stellar.expert/explorer/testnet/account/" : "https://stellar.expert/explorer/public/account/"
            let exploreLink =  baseUrl + address
            return URL(string: exploreLink)
        case .xrp:
            return URL(string: "https://xrpscan.com/account/\(address)")
        case .tezos:
            return URL(string: "https://tezblock.io/account/\(address)")
        case .dogecoin:
            return URL(string: "https://blockchair.com/dogecoin/address/\(address)")
        case .bsc:
            let baseUrl = isTestnet ? "https://testnet.bscscan.com/address/" : "https://bscscan.com/address/"
            let link = baseUrl + address
            return URL(string: link)
        case .polygon:
            let baseUrl = isTestnet ? "https://explorer-mumbai.maticvigil.com/address/" : "https://polygonscan.com/address/"
            let link = baseUrl + address
            return URL(string: link)
        case .avalanche:
            let baseUrl = isTestnet ? "https://testnet.snowtrace.io/address/" : "https://snowtrace.io/address/"
            let link = baseUrl + address
            return URL(string: link)
        case .solana:
            let baseUrl = "https://explorer.solana.com/address/"
            let cluster = isTestnet ? "?cluster=testnet" : ""
            return URL(string: baseUrl + address + cluster)
        case .fantom:
            let baseUrl = isTestnet ? "https://testnet.ftmscan.com/address/" : "https://ftmscan.com/address/"
            let link = baseUrl + address
            return URL(string: link)
        case .polkadot:
            let subdomain = isTestnet ? "westend" : "polkadot"
            return URL(string: "https://\(subdomain).subscan.io/account/\(address)")
        case .kusama:
            return URL(string: "https://kusama.subscan.io/account/\(address)")
        }
    }
}

// MARK: - Helpers
@available(iOS 13.0, *)
extension Blockchain {
    public var decimalValue: Decimal {
        return pow(Decimal(10), decimalCount)
    }
}

// MARK: - Card's factory
@available(iOS 13.0, *)
extension Blockchain {
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
        case "binance", "binanceasset": return .binance(testnet: isTestnet)
        case "cardano": return .cardano(shelley: false)
        case "cardano-s": return .cardano(shelley: true)
        case "xrp": return .xrp(curve: curve)
        case "duc": return .ducatus
        case "xtz": return .tezos(curve: curve)
        case "doge": return .dogecoin
        case "bsc": return .bsc(testnet: isTestnet)
        case "polygon": return .polygon(testnet: isTestnet)
        case "avalanche": return .avalanche(testnet: isTestnet)
        case "solana": return .solana(testnet: isTestnet)
        case "fantom": return .fantom(testnet: isTestnet)
        case "polkadot": return .polkadot(testnet: isTestnet)
        case "kusama": return .kusama
        default: return nil
        }
    }
}
