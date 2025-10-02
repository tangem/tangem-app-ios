//
//  StakingValidatorsCompactViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import Combine
import TangemStaking

class StakingValidatorsCompactViewModel: ObservableObject, Identifiable {
    // Use the estimated size as initial value
    @Published var viewSize: CGSize = .init(width: 361, height: 88)
    @Published var selectedValidator: ValidatorCompactViewData?
    @Published var canEditValidator: Bool

    private let rewardRateFormatter = StakingValidatorRewardRateFormatter()
    private var bag: Set<AnyCancellable> = []

    init(input: StakingValidatorsInput, preferredValidatorsCount: Int) {
        canEditValidator = preferredValidatorsCount > 1

        bind(input: input)
    }

    func bind(input: StakingValidatorsInput) {
        input
            .selectedValidatorPublisher
            .withWeakCaptureOf(self)
            .map { viewModel, validator in
                viewModel.mapToValidatorCompactViewData(validator: validator)
            }
            .receive(on: DispatchQueue.main)
            .assign(to: \.selectedValidator, on: self, ownership: .weak)
            .store(in: &bag)
    }

    private func mapToValidatorCompactViewData(validator: ValidatorInfo) -> ValidatorCompactViewData {
        ValidatorCompactViewData(
            address: validator.address,
            name: validator.name,
            imageURL: validator.iconURL,
            aprFormatted: rewardRateFormatter.format(validator: validator, type: .short)
        )
    }
}
