//
//  Blockchain+.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

extension Blockchain {
    static var testnetId = "/test"

    // Init blockchain from id with default params
    init?(from stringId: String) {
        let isTestnet = stringId.contains(Blockchain.testnetId)
        let rawId = stringId.remove(Blockchain.testnetId)
        switch rawId {
        case "bitcoin": self = .bitcoin(testnet: isTestnet)
        case "stellar": self = .stellar(testnet: isTestnet)
        case "ethereum": self = .ethereum(testnet: isTestnet)
        case "ethereum-classic": self = .ethereumClassic(testnet: isTestnet)
        case "litecoin": self = .litecoin
        case "rootstock", "rsk": self = .rsk
        case "bitcoin-cash": self = .bitcoinCash(testnet: isTestnet)
        case "binancecoin", "bnb": self = .binance(testnet: isTestnet)
        case "cardano": self = .cardano
        case "ripple", "xrp": self = .xrp(curve: .secp256k1)
        case "ducatus": self = .ducatus
        case "tezos": self = .tezos(curve: .secp256k1)
        case "dogecoin": self = .dogecoin
        case "binance-smart-chain", "binance_smart_chain": self = .bsc(testnet: isTestnet)
        case "polygon-pos", "matic-network", "polygon": self = .polygon(testnet: isTestnet)
        case "avalanche", "avalanche-2": self = .avalanche(testnet: isTestnet)
        case "solana": self = .solana(testnet: isTestnet)
        case "fantom": self = .fantom(testnet: isTestnet)
        case "polkadot": self = .polkadot(testnet: isTestnet)
        case "kusama": self = .kusama
        case "aleph-zero": self = .azero(testnet: isTestnet)
        case "tron": self = .tron(testnet: isTestnet)
        case "arbitrum", "arbitrum-one": self = .arbitrum(testnet: isTestnet)
        case "dash": self = .dash(testnet: isTestnet)
        case "xdai", "gnosis": self = .gnosis
        case "optimistic-ethereum": self = .optimism(testnet: isTestnet)
        case "ethereum-pow-iou": self = .ethereumPoW(testnet: isTestnet)
        case "ethereumfair": self = .ethereumFair
        case "sxdai": self = .saltPay // [REDACTED_TODO_COMMENT]
        case "the-open-network": self = .ton(testnet: isTestnet)
        case "kava": self = .kava(testnet: isTestnet)
        case "kaspa": self = .kaspa
        case "ravencoin": self = .ravencoin(testnet: isTestnet)
        case "cosmos": self = .cosmos(testnet: isTestnet)
        case "terra", "terra-luna": self = .terraV1
        case "terra-2", "terra-luna-2": self = .terraV2
        case "crypto-com-chain", "cronos": self = .cronos
        case "telos": self = .telos(testnet: isTestnet)
        case "octaspace": self = .octa
        default:
            AppLog.shared.debug("⚠️⚠️⚠️ Failed to map network ID \"\(stringId)\"")
            return nil
        }
    }

    /// The ID from `CoinGecko`
    var id: String {
        switch self {
        case .binance: return "binancecoin"
        case .bitcoin: return "bitcoin"
        case .bitcoinCash: return "bitcoin-cash"
        case .cardano: return "cardano"
        case .ducatus: return "ducatus"
        case .ethereum: return "ethereum"
        case .ethereumClassic: return "ethereum-classic"
        case .litecoin: return "litecoin"
        case .rsk: return "rootstock"
        case .stellar: return "stellar"
        case .tezos: return "tezos"
        case .xrp: return "ripple"
        case .dogecoin: return "dogecoin"
        case .bsc: return "binancecoin"
        case .polygon: return "matic-network"
        case .avalanche: return "avalanche-2"
        case .solana: return "solana"
        case .fantom: return "fantom"
        case .polkadot: return "polkadot"
        case .kusama: return "kusama"
        case .azero: return "aleph-zero"
        case .tron: return "tron"
        case .arbitrum: return "arbitrum-one"
        case .dash: return "dash"
        case .gnosis: return "xdai"
        case .optimism: return "optimistic-ethereum"
        case .ethereumPoW: return "ethereum-pow-iou"
        case .ethereumFair: return "ethereumfair"
        case .saltPay: return "sxdai"
        case .ton: return "the-open-network"
        case .kava: return "kava"
        case .kaspa: return "kaspa"
        case .ravencoin: return "ravencoin"
        case .cosmos: return "cosmos"
        case .terraV1: return "terra-luna"
        case .terraV2: return "terra-luna-2"
        case .cronos: return "crypto-com-chain"
        case .telos: return "telos"
        case .octa: return "octaspace"
        case .chia: return "chia"
        }
    }

    /// The ID for `Tangem API`. Used to save a list of user tokens
    var networkId: String {
        isTestnet ? "\(rawNetworkId)\(Blockchain.testnetId)" : rawNetworkId
    }

    /// Used to for currency rate from `Tangem API`
    var currencyId: String {
        switch self {
        case .arbitrum(let testnet), .optimism(let testnet):
            return Blockchain.ethereum(testnet: testnet).id
        default:
            return id
        }
    }

    /// Used to get icon from `Tokens.xcassets`
    var iconName: String {
        let rawId = rawStringId

        if rawId == "binance" {
            return "bsc"
        }

        return rawId
    }

    /// Used to get icon from `Tokens.xcassets`
    var iconNameFilled: String { "\(iconName).fill" }

    private var rawStringId: String {
        var name = "\(self)".lowercased()

        if let index = name.firstIndex(of: "(") {
            name = String(name.prefix(upTo: index))
        }

        return name
    }

    private var rawNetworkId: String {
        switch self {
        case .binance: return "binancecoin"
        case .bitcoin: return "bitcoin"
        case .bitcoinCash: return "bitcoin-cash"
        case .cardano: return "cardano"
        case .ducatus: return "ducatus"
        case .ethereum: return "ethereum"
        case .ethereumClassic: return "ethereum-classic"
        case .litecoin: return "litecoin"
        case .rsk: return "rootstock"
        case .stellar: return "stellar"
        case .tezos: return "tezos"
        case .xrp: return "xrp"
        case .dogecoin: return "dogecoin"
        case .bsc: return "binance-smart-chain"
        case .polygon: return "polygon-pos"
        case .avalanche: return "avalanche"
        case .solana: return "solana"
        case .fantom: return "fantom"
        case .polkadot: return "polkadot"
        case .kusama: return "kusama"
        case .azero: return "aleph-zero"
        case .tron: return "tron"
        case .arbitrum: return "arbitrum-one"
        case .dash: return "dash"
        case .gnosis: return "xdai"
        case .optimism: return "optimistic-ethereum"
        case .ethereumPoW: return "ethereum-pow-iou"
        case .ethereumFair: return "ethereumfair"
        case .saltPay: return "sxdai"
        case .ton: return "the-open-network"
        case .kava: return "kava"
        case .kaspa: return "kaspa"
        case .ravencoin: return "ravencoin"
        case .cosmos: return "cosmos"
        case .terraV1: return "terra"
        case .terraV2: return "terra-2"
        case .cronos: return "cronos"
        case .telos: return "telos"
        case .octa: return "octaspace"
        case .chia: return "chia"
        }
    }
}
