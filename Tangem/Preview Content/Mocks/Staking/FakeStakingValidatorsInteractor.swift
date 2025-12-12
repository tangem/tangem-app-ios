//
//  FakeStakingValidatorsInteractor.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemStaking

struct FakeStakingValidatorsInteractor: StakingTargetsInteractor {
    var targetsPublisher: AnyPublisher<[StakingTargetInfo], Never> {
        .just(output: [
            .init(
                address: UUID().uuidString,
                name: "InfStones",
                preferred: true,
                partner: false,
                iconURL: URL(string: "https://assets.stakek.it/validators/infstones.png")!,
                rewardType: .apr,
                rewardRate: Decimal(0.008),
                status: .active
            ),
            .init(
                address: UUID().uuidString,
                name: "Aconcagua",
                preferred: true,
                partner: false,
                iconURL: URL(string: "https://assets.stakek.it/validators/coinbase.png")!,
                rewardType: .apr,
                rewardRate: Decimal(0.023),
                status: .active
            ),
        ])
    }

    var selectedTargetPublisher: AnyPublisher<StakingTargetInfo, Never> {
        targetsPublisher.compactMap { $0.first }.eraseToAnyPublisher()
    }

    func userDidSelect(targetAddress: String) {}
}
