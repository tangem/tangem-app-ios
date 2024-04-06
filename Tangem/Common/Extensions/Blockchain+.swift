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
    /// Should be used as blockchain identifier
    var coinId: String {
        id(type: .coin)
    }

    /// Should be used to:
    /// - Get a list of coins as the `networkIds` parameter
    /// - Synchronization of user coins on the server
    var networkId: String {
        id(type: .network)
    }

    /// Should be used to get the actual currency rate
    var currencyId: String {
        switch self {
        case .arbitrum(let testnet), .optimism(let testnet),
             .aurora(let testnet), .manta(let testnet),
             .zkSync(let testnet), .polygonZkEVM(let testnet):
            return Blockchain.ethereum(testnet: testnet).coinId
        default:
            return coinId
        }
    }

    /// Should be used to get a icon from the`Tokens.xcassets` file
    var iconName: String {
        var name = "\(self)".lowercased()

        if let index = name.firstIndex(of: "(") {
            name = String(name.prefix(upTo: index))
        }

        if name == "binance" {
            return "bsc"
        }

        return name
    }

    /// Should be used to get a filled icon from the`Tokens.xcassets` file
    var iconNameFilled: String { "\(iconName).fill" }
}

// MARK: - Blockchain ID

private extension Blockchain {
    func id(type: IDType) -> String {
        switch self {
        case .bitcoin: return "bitcoin"
        case .litecoin: return "litecoin"
        case .stellar: return "stellar"
        case .ethereum: return "ethereum"
        case .ethereumPoW: return "ethereum-pow-iou"
        case .disChain: return "ethereumfair" // keep existing id for compatibility
        case .ethereumClassic: return "ethereum-classic"
        case .rsk: return "rootstock"
        case .bitcoinCash: return "bitcoin-cash"
        case .binance: return "binancecoin"
        case .cardano: return "cardano"
        case .xrp:
            switch type {
            case .network: return "xrp"
            case .coin: return "ripple"
            }
        case .ducatus: return "ducatus"
        case .tezos: return "tezos"
        case .dogecoin: return "dogecoin"
        case .bsc:
            switch type {
            case .network: return "binance-smart-chain"
            case .coin: return "binancecoin"
            }
        case .polygon:
            switch type {
            case .network: return "polygon-pos"
            case .coin: return "matic-network"
            }
        case .avalanche:
            switch type {
            case .network: return "avalanche"
            case .coin: return "avalanche-2"
            }
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
        case .ton: return "the-open-network"
        case .kava: return "kava"
        case .kaspa: return "kaspa"
        case .ravencoin: return "ravencoin"
        case .cosmos: return "cosmos"
        case .terraV1:
            switch type {
            case .network: return "terra"
            case .coin: return "terra-luna"
            }
        case .terraV2:
            switch type {
            case .network: return "terra-2"
            case .coin: return "terra-luna-2"
            }
        case .cronos:
            switch type {
            case .network: return "cronos"
            case .coin: return "crypto-com-chain"
            }
        case .telos: return "telos"
        case .octa: return "octaspace"
        case .chia: return "chia"
        case .near:
            switch type {
            case .network: return "near-protocol"
            case .coin: return "near"
            }
        case .decimal:
            return "decimal"
        case .veChain:
            return "vechain"
        case .xdc:
            switch type {
            case .network: return "xdc-network"
            case .coin: return "xdce-crowd-sale"
            }
        case .algorand: return "algorand"
        case .shibarium:
            switch type {
            case .network: return "shibarium"
            case .coin: return "bone-shibaswap"
            }
        case .aptos:
            return "aptos"
        case .hedera:
            return "hedera-hashgraph"
        case .areon:
            return "areon-network"
        case .playa3ullGames:
            switch type {
            case .network: return "playa3ull-games"
            case .coin: return "playa3ull-games-2"
            }
        case .pulsechain:
            return "pulsechain"
        case .aurora:
            switch type {
            case .network: return "aurora"
            case .coin: return "aurora-ethereum"
            }
        case .manta:
            switch type {
            case .network: return "manta-network"
            case .coin: return "manta-network-ethereum"
            }
        case .zkSync:
            switch type {
            case .network: return "zksync"
            case .coin: return "zksync-ethereum"
            }
        case .moonbeam:
            return "moonbeam"
        case .polygonZkEVM:
            switch type {
            case .network: return "polygon-zkevm"
            case .coin: return "polygon-zkevm-ethereum"
            }
        case .moonriver:
            return "moonriver"
        case .mantle:
            return "mantle"
        case .flare:
            switch type {
            case .network: return "flare-network"
            case .coin: return "flare-networks"
            }
        case .taraxa:
            return "taraxa"
        case .radiant:
            return "radiant"
        }
    }

    enum IDType: Hashable {
        case network
        case coin
    }
}

extension Set<Blockchain> {
    subscript(networkId: String) -> Blockchain? {
        // The "test" suffix no longer needed
        // since the coins are selected from the supported blockchains list
        // But we should remove it to support old application versions
        let testnetId = "/test"

        let clearNetworkId = networkId.replacingOccurrences(of: testnetId, with: "")
        if let blockchain = first(where: { $0.networkId == clearNetworkId }) {
            return blockchain
        }

        AppLog.shared.debug("⚠️⚠️⚠️ Blockchain with id: \(networkId) isn't contained in supported blockchains")
        return nil
    }
}

extension Blockchain {
    var feeDisplayName: String {
        switch self {
        case .arbitrum, .optimism:
            return displayName + " (\(currencySymbol))"
        default:
            return currencySymbol
        }
    }
}
