//
//  StakingTargetsCompactViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import Combine
import TangemStaking

class StakingTargetsCompactViewModel: ObservableObject, Identifiable {
    @Published var selectedTarget: StakingTargetCompactViewData?
    @Published var canEditTarget: Bool

    private let rewardRateFormatter = StakingTargetRewardRateFormatter()
    private var bag: Set<AnyCancellable> = []

    init(input: StakingTargetsInput, preferredTargetsCount: Int) {
        canEditTarget = preferredTargetsCount > 1

        bind(input: input)
    }

    func bind(input: StakingTargetsInput) {
        input
            .selectedTargetPublisher
            .withWeakCaptureOf(self)
            .map { viewModel, target in
                viewModel.mapToTargetCompactViewData(target: target)
            }
            .receive(on: DispatchQueue.main)
            .assign(to: \.selectedTarget, on: self, ownership: .weak)
            .store(in: &bag)
    }

    private func mapToTargetCompactViewData(target: StakingTargetInfo) -> StakingTargetCompactViewData {
        StakingTargetCompactViewData(
            address: target.address,
            name: target.name,
            imageURL: target.iconURL,
            aprFormatted: rewardRateFormatter.format(target: target, type: .short)
        )
    }
}
