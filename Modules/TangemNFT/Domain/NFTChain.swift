//
//  NFTChain.swift
//  TangemNFT
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

/// An aggregated list of supported chains from https://docs.moralis.com/supported-web3data-apis and https://docs.nftscan.com/
public enum NFTChain: Hashable {
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

    // [REDACTED_TODO_COMMENT]
    case pulsechain

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
