//
//  StakingValidatorsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.xw
//

import Combine
import TangemStaking
import SwiftUI

final class StakingValidatorsViewModel: ObservableObject, Identifiable {
    // MARK: - ViewState

    @Published var validators: [ValidatorViewData] = []
    @Published var selectedValidator: String = ""

    private var initialSelectedValidator: String?

    // MARK: - Dependencies

    private let interactor: StakingValidatorsInteractor
    private let analyticsLogger: SendValidatorsAnalyticsLogger

    private let rewardRateFormatter = StakingValidatorRewardRateFormatter()
    private var bag: Set<AnyCancellable> = []

    init(interactor: StakingValidatorsInteractor, analyticsLogger: SendValidatorsAnalyticsLogger) {
        self.interactor = interactor
        self.analyticsLogger = analyticsLogger

        bind()
    }

    func onAppear() {}

    func onDisappear() {
        if selectedValidator != initialSelectedValidator, validators.contains(where: { $0.address == selectedValidator }) {
            analyticsLogger.logStakingValidatorChosen()
        }
    }
}

// MARK: - Private

private extension StakingValidatorsViewModel {
    func bind() {
        interactor
            .validatorsPublisher
            .withWeakCaptureOf(self)
            .map { viewModel, validators in
                validators.map { validatorInfo in
                    let percentFormatted = viewModel.rewardRateFormatter.format(
                        validator: validatorInfo, type: .full
                    )

                    return ValidatorViewData(
                        address: validatorInfo.address,
                        name: validatorInfo.name,
                        imageURL: validatorInfo.iconURL,
                        isPartner: validatorInfo.partner,
                        subtitleType: .selection(formatted: percentFormatted),
                        detailsType: .checkmark
                    )
                }
            }
            .receive(on: DispatchQueue.main)
            .assign(to: \.validators, on: self, ownership: .weak)
            .store(in: &bag)

        interactor
            .selectedValidatorPublisher
            .removeDuplicates()
            .withWeakCaptureOf(self)
            // If viewModel already has selectedValidator
            .filter { $0.selectedValidator != $1.address }
            .receive(on: DispatchQueue.main)
            .sink { viewModel, selectedValidator in
                viewModel.selectedValidator = selectedValidator.address
                if viewModel.initialSelectedValidator == nil {
                    viewModel.initialSelectedValidator = selectedValidator.address
                }
            }
            .store(in: &bag)

        $selectedValidator
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { viewModel, validatorAddress in
                viewModel.interactor.userDidSelect(validatorAddress: validatorAddress)
            }
            .store(in: &bag)
    }
}

extension StakingValidatorsViewModel {
    struct Input {
        let validators: [ValidatorInfo]
    }
}
