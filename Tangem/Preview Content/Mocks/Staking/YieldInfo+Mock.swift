//
//  StakingYieldInfo+Mock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking

extension StakingYieldInfo {
    static let mock: StakingYieldInfo = .init(
        id: "tron-trx-native-staking",
        isAvailable: true,
        rewardType: .apr,
        rewardRateValues: .single(0.03712381),
        enterMinimumRequirement: 1,
        exitMinimumRequirement: 1,
        validators: [
            .init(
                address: UUID().uuidString,
                name: "InfStones",
                preferred: true,
                partner: false,
                iconURL: URL(string: "https://assets.stakek.it/validators/infstones.png"),
                rewardType: .apr,
                rewardRate: 0.08,
                status: .active
            ),
            .init(
                address: UUID().uuidString,
                name: "Aconcagua",
                preferred: true,
                partner: false,
                iconURL: URL(string: "https://assets.stakek.it/validators/aconcagua.png"),
                rewardType: .apr,
                rewardRate: 0.032,
                status: .active
            ),
        ],
        preferredValidators: [
            .init(
                address: UUID().uuidString,
                name: "InfStones",
                preferred: true,
                partner: false,
                iconURL: URL(string: "https://assets.stakek.it/validators/infstones.png"),
                rewardType: .apr,
                rewardRate: 0.08,
                status: .active
            ),
            .init(
                address: UUID().uuidString,
                name: "Aconcagua",
                preferred: true,
                partner: false,
                iconURL: URL(string: "https://assets.stakek.it/validators/aconcagua.png"),
                rewardType: .apr,
                rewardRate: 0.032,
                status: .active
            ),
        ],
        item: .init(network: .tron, contractAddress: nil, name: "", decimals: 0, symbol: ""),
        unbondingPeriod: .days(14),
        warmupPeriod: .days(0),
        rewardClaimingType: .manual,
        rewardScheduleType: .daily
    )
}
