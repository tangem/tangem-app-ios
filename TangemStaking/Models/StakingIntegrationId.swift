//
//  StakingIntegrationId.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public enum StakingIntegrationId: String {
    case solana = "solana-sol-native-multivalidator-staking"
    case cosmos = "cosmos-atom-native-staking"
    case matic = "ethereum-matic-native-staking"
    case tron = "tron-trx-native-staking"
    case bsc = "bsc-bnb-native-staking"
    case ton = "ton-ton-chorus-one-pools-staking"
    case cardano = "cardano-ada-native-staking"
    case ethereumP2P = "ethereum-p2p-staking"
}
