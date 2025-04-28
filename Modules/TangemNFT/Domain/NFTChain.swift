//
//  NFTChain.swift
//  TangemNFT
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

/// An aggregated list of supported chains from https://docs.moralis.com/supported-web3data-apis and https://docs.nftscan.com/
public enum NFTChain: Hashable, Sendable {
    case ethereum(isTestnet: Bool)

    case polygon(isTestnet: Bool)

    case bsc(isTestnet: Bool)

    case avalanche

    case fantom

    case cronos

    case arbitrum

    case gnosis(isTestnet: Bool)

    case chiliz(isTestnet: Bool)

    case base(isTestnet: Bool)

    case optimism

    case moonbeam(isTestnet: Bool)

    case moonriver

    case solana

    @available(*, unavailable, message: "The network is not supported yet by the app")
    case linea(isTestnet: Bool)

    @available(*, unavailable, message: "The network is not supported yet by the app")
    case flow(isTestnet: Bool)

    @available(*, unavailable, message: "The network is not supported yet by the app")
    case ronin(isTestnet: Bool)

    @available(*, unavailable, message: "The network is not supported yet by the app")
    case lisk(isTestnet: Bool)

    @available(*, unavailable, message: "NFTs are not supported for this network yet")
    case btc

    @available(*, unavailable, message: "NFTs are not supported for this network yet")
    case aptos

    @available(*, unavailable, message: "NFTs are not supported for this network yet")
    case ton
}

// MARK: - Identifiable protocol conformance

extension NFTChain: Identifiable {
    public var id: String {
        switch self {
        case .ethereum(let isTestnet):
            return "ethereum" + isTestnet.testnetSuffix
        case .polygon(let isTestnet):
            return "polygon" + isTestnet.testnetSuffix
        case .bsc(let isTestnet):
            return "bsc" + isTestnet.testnetSuffix
        case .avalanche:
            return "avalanche"
        case .fantom:
            return "fantom"
        case .cronos:
            return "cronos"
        case .arbitrum:
            return "arbitrum"
        case .gnosis(let isTestnet):
            return "gnosis" + isTestnet.testnetSuffix
        case .chiliz(let isTestnet):
            return "chiliz" + isTestnet.testnetSuffix
        case .base(let isTestnet):
            return "base" + isTestnet.testnetSuffix
        case .optimism:
            return "optimism"
        case .moonbeam(let isTestnet):
            return "moonbeam" + isTestnet.testnetSuffix
        case .moonriver:
            return "moonriver"
        case .solana:
            return "solana"
        }
    }
}

// MARK: - Convenience extensions

public extension NFTChain {
    /// Poor man's `CaseIterable`.
    static func allCases(isTestnet: Bool) -> Set<NFTChain> {
        return [
            .ethereum(isTestnet: isTestnet),
            .polygon(isTestnet: isTestnet),
            .bsc(isTestnet: isTestnet),
            .avalanche,
            .fantom,
            .cronos,
            .arbitrum,
            .gnosis(isTestnet: isTestnet),
            .chiliz(isTestnet: isTestnet),
            .base(isTestnet: isTestnet),
            .optimism,
            .moonbeam(isTestnet: isTestnet),
            .moonriver,
            .solana,
        ]
    }
}

private extension Bool {
    var testnetSuffix: String {
        return self ? "-testnet" : ""
    }
}
