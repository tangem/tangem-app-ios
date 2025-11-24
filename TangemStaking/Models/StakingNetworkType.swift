//
//  StakingNetworkType.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public enum StakingNetworkType: String, RawRepresentable {
    case ethereum
    case bsc = "binance-smart-chain"
    case ton = "the-open-network"
    case solana
    case cosmos
    case cardano
    case tron
    case polkadot
    case kava
    case near = "near-protocol"
}

extension StakingNetworkType {
    init?(stakeKitNetworkType: StakeKitNetworkType) {
        switch stakeKitNetworkType {
        case .ethereum: self = .ethereum
        case .binance: self = .bsc
        case .ton: self = .ton
        case .solana: self = .solana
        case .cosmos: self = .cosmos
        case .cardano: self = .cardano
        case .polkadot: self = .polkadot
        case .tron: self = .tron
        case .kava: self = .kava
        case .near: self = .near
        default: return nil
        }
    }

    var asStakeKitNetworkType: StakeKitNetworkType {
        switch self {
        case .ethereum: .ethereum
        case .bsc: .binance
        case .ton: .ton
        case .solana: .solana
        case .cosmos: .cosmos
        case .cardano: .cardano
        case .polkadot: .polkadot
        case .tron: .tron
        case .kava: .kava
        case .near: .near
        }
    }
}
