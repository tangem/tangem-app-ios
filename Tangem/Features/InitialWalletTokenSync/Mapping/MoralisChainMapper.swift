//
//  MoralisChainMapper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation
import BlockchainSdk

/// Maps app `Blockchain` to Moralis `chain` query parameter value.
///
/// Moralis docs:
/// https://docs.moralis.com/data-api/evm/wallet/token-balances
///
/// The chain to query.
///
/// Available options (from Moralis docs):
/// `eth`, `0x1`, `sepolia`, `0xaa36a7`, `polygon`, `0x89`, `bsc`, `0x38`,
/// `bsc testnet`, `0x61`, `avalanche`, `0xa86a`, `fantom`, `0xfa`, `cronos`, `0x19`,
/// `arbitrum`, `0xa4b1`, `chiliz`, `0x15b38`, `chiliz testnet`, `0x15b32`, `gnosis`, `0x64`,
/// `gnosis testnet`, `0x27d8`, `base`, `0x2105`, `base sepolia`, `0x14a34`, `optimism`, `0xa`,
/// `polygon amoy`, `0x13882`, `linea`, `0xe708`, `moonbeam`, `0x504`, `moonriver`, `0x505`,
/// `moonbase`, `0x507`, `linea sepolia`, `0xe705`, `flow`, `0x2eb`, `flow-testnet`, `0x221`,
/// `ronin`, `0x7e4`, `ronin-testnet`, `0x7e5`, `lisk`, `0x46f`, `lisk-sepolia`, `0x106a`,
/// `pulse`, `0x171`, `sei-testnet`, `0x530`, `sei`, `0x531`, `monad`, `0x8f`.
///
/// Example:
/// `"eth"`.
///
/// This mapper intentionally supports only chains available in `Blockchain` and used by
/// `InitialWalletTokenSync`. Unsupported chains are mapped to controlled errors.
struct MoralisChainMapper {
    /// Returns Moralis `chain` query value for given app blockchain.
    func map(blockchain: Blockchain) throws -> String {
        guard blockchain.isEvm else {
            throw MoralisTokenBalanceError.unsupportedChain(blockchain)
        }

        switch blockchain {
        case .ethereum(let isTestnet):
            return isTestnet ? "sepolia" : "eth"
        case .polygon(let isTestnet):
            return isTestnet ? "polygon amoy" : "polygon"
        case .bsc(let isTestnet):
            return isTestnet ? "bsc testnet" : "bsc"
        case .avalanche(let isTestnet):
            guard !isTestnet else {
                throw MoralisTokenBalanceError.unsupportedNetwork(networkId: blockchain.networkId)
            }
            return "avalanche"
        case .fantom(let isTestnet):
            guard !isTestnet else {
                throw MoralisTokenBalanceError.unsupportedNetwork(networkId: blockchain.networkId)
            }
            return "fantom"
        case .cronos:
            return "cronos"
        case .arbitrum(let isTestnet):
            guard !isTestnet else {
                throw MoralisTokenBalanceError.unsupportedNetwork(networkId: blockchain.networkId)
            }
            return "arbitrum"
        case .gnosis:
            return "gnosis"
        case .base(let isTestnet):
            return isTestnet ? "base sepolia" : "base"
        case .optimism(let isTestnet):
            guard !isTestnet else {
                throw MoralisTokenBalanceError.unsupportedNetwork(networkId: blockchain.networkId)
            }
            return "optimism"
        case .linea(let isTestnet):
            return isTestnet ? "linea sepolia" : "linea"
        case .moonbeam(let isTestnet):
            return isTestnet ? "moonbase" : "moonbeam"
        case .moonriver(let isTestnet):
            guard !isTestnet else {
                throw MoralisTokenBalanceError.unsupportedNetwork(networkId: blockchain.networkId)
            }
            return "moonriver"
        case .chiliz(let isTestnet):
            return isTestnet ? "chiliz testnet" : "chiliz"
        case .pulsechain:
            return "pulse"
        case .sei(let isTestnet):
            return isTestnet ? "sei-testnet" : "sei"
        case .monad:
            return "monad"
        default:
            throw MoralisTokenBalanceError.unsupportedNetwork(networkId: blockchain.networkId)
        }
    }
}
