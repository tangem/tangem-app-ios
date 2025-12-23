//
//  StakingTargetsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.xw
//

import Combine
import TangemStaking
import SwiftUI

final class StakingTargetsViewModel: ObservableObject, Identifiable {
    // MARK: - ViewState

    @Published var targets: [StakingTargetViewData] = []
    @Published var selectedTarget: String = ""

    private var initialSelectedTarget: String?

    // MARK: - Dependencies

    private let interactor: StakingTargetsInteractor
    private let analyticsLogger: SendTargetsAnalyticsLogger

    private let rewardRateFormatter = StakingTargetRewardRateFormatter()
    private var bag: Set<AnyCancellable> = []

    init(interactor: StakingTargetsInteractor, analyticsLogger: SendTargetsAnalyticsLogger) {
        self.interactor = interactor
        self.analyticsLogger = analyticsLogger

        bind()
    }

    func onAppear() {}

    func onDisappear() {
        if selectedTarget != initialSelectedTarget, targets.contains(where: { $0.address == selectedTarget }) {
            analyticsLogger.logStakingTargetChosen()
        }
    }
}

// MARK: - Private

private extension StakingTargetsViewModel {
    func bind() {
        interactor
            .targetsPublisher
            .withWeakCaptureOf(self)
            .map { viewModel, targets in
                targets.map { targetInfo in
                    let percentFormatted = viewModel.rewardRateFormatter.format(
                        target: targetInfo, type: .full
                    )

                    return StakingTargetViewData(
                        address: targetInfo.address,
                        name: targetInfo.name,
                        imageURL: targetInfo.iconURL,
                        isPartner: targetInfo.partner,
                        subtitleType: .selection(formatted: percentFormatted),
                        detailsType: .checkmark
                    )
                }
            }
            .receive(on: DispatchQueue.main)
            .assign(to: \.targets, on: self, ownership: .weak)
            .store(in: &bag)

        interactor
            .selectedTargetPublisher
            .removeDuplicates()
            .withWeakCaptureOf(self)
            // If viewModel already has selectedValidator
            .filter { $0.selectedTarget != $1.address }
            .receive(on: DispatchQueue.main)
            .sink { viewModel, selectedTarget in
                viewModel.selectedTarget = selectedTarget.address
                if viewModel.initialSelectedTarget == nil {
                    viewModel.initialSelectedTarget = selectedTarget.address
                }
            }
            .store(in: &bag)

        $selectedTarget
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { viewModel, targetAddress in
                viewModel.interactor.userDidSelect(targetAddress: targetAddress)
            }
            .store(in: &bag)
    }
}

extension StakingTargetsViewModel {
    struct Input {
        let targets: [StakingTargetInfo]
    }
}
