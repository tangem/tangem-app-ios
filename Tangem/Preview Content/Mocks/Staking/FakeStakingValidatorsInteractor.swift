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

struct FakeStakingValidatorsInteractor: StakingValidatorsInteractor {
    var validatorsPublisher: AnyPublisher<[ValidatorInfo], Never> {
        .just(output: [
            .init(
                address: UUID().uuidString,
                name: "InfStones",
                preferred: true,
                partner: false,
                iconURL: URL(string: "https://assets.stakek.it/validators/infstones.png")!,
                apr: 0.008,
                status: .active
            ),
            .init(
                address: UUID().uuidString,
                name: "Aconcagua",
                preferred: true,
                partner: false,
                iconURL: URL(string: "https://assets.stakek.it/validators/coinbase.png")!,
                apr: 0.023,
                status: .active
            ),
        ])
    }

    var selectedValidatorPublisher: AnyPublisher<ValidatorInfo, Never> {
        validatorsPublisher.compactMap { $0.first }.eraseToAnyPublisher()
    }

    func userDidSelect(validatorAddress: String) {}
}
