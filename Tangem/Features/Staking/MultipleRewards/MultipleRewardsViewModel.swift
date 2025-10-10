//
//  MultipleRewardsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemLocalization
import TangemStaking
import struct TangemUIUtils.AlertBinder
import struct TangemUIUtils.ConfirmationDialogViewModel

final class MultipleRewardsViewModel: ObservableObject, Identifiable {
    // MARK: - ViewState

    @Published var validators: [ValidatorViewData] = []
    @Published var confirmationDialog: ConfirmationDialogViewModel?
    @Published var alert: AlertBinder?

    // MARK: - Dependencies

    private let tokenItem: TokenItem
    private let stakingManager: StakingManager
    private weak var coordinator: MultipleRewardsRoutable?

    private let rewardRateFormatter = StakingValidatorRewardRateFormatter()
    private let balanceFormatter = BalanceFormatter()
    private var bag: Set<AnyCancellable> = []

    init(
        tokenItem: TokenItem,
        stakingManager: StakingManager,
        coordinator: MultipleRewardsRoutable
    ) {
        self.tokenItem = tokenItem
        self.stakingManager = stakingManager
        self.coordinator = coordinator

        bind()
    }

    func dismiss() {
        coordinator?.dismiss()
    }
}

// MARK: - Private

private extension MultipleRewardsViewModel {
    func bind() {
        stakingManager
            .statePublisher
            .withWeakCaptureOf(self)
            .flatMap { viewModel, state in
                switch state {
                case .staked(let staked):
                    let data = staked.balances.rewards().compactMap { balance in
                        viewModel.mapToValidatorViewData(balance: balance, yield: staked.yieldInfo)
                    }
                    return Just(data).eraseToAnyPublisher()
                default:
                    // Do nothing
                    return Empty().eraseToAnyPublisher()
                }
            }
            .receive(on: DispatchQueue.main)
            .assign(to: \.validators, on: self, ownership: .weak)
            .store(in: &bag)
    }

    func mapToValidatorViewData(balance: StakingBalance, yield: StakingYieldInfo) -> ValidatorViewData? {
        guard let validator = balance.validatorType.validator else {
            return nil
        }

        let balanceCryptoFormatted = balanceFormatter.formatCryptoBalance(
            balance.amount,
            currencyCode: tokenItem.currencySymbol
        )
        let balanceFiat = tokenItem.currencyId.flatMap {
            BalanceConverter().convertToFiat(balance.amount, currencyId: $0)
        }
        let balanceFiatFormatted = balanceFormatter.formatFiatBalance(balanceFiat)

        let percent = rewardRateFormatter.format(validator: validator, type: .short)
        let subtitleType: ValidatorViewData.SubtitleType = .active(formatted: percent)

        return ValidatorViewData(
            address: validator.address,
            name: validator.name,
            imageURL: validator.iconURL,
            subtitleType: subtitleType,
            detailsType: .balance(.init(crypto: balanceCryptoFormatted, fiat: balanceFiatFormatted)) { [weak self] in
                self?.openStakingSingleActionFlow(balance: balance, validators: yield.validators)
            }
        )
    }

    func openStakingSingleActionFlow(balance: StakingBalance, validators: [ValidatorInfo]) {
        do {
            let action = try PendingActionMapper(balance: balance, validators: validators).getAction()
            switch action {
            case .single(let action):
                coordinator?.openStakingSingleActionFlow(action: action)
            case .multiple(let actions):
                let buttons = actions.map { action in
                    ConfirmationDialogViewModel.Button(title: action.type.title) { [weak self] in
                        self?.coordinator?.openStakingSingleActionFlow(action: action)
                    }
                }

                confirmationDialog = ConfirmationDialogViewModel(
                    title: Localization.commonSelectAction,
                    buttons: buttons + [ConfirmationDialogViewModel.Button.cancel]
                )
            }
        } catch {
            alert = AlertBuilder.makeOkErrorAlert(message: error.localizedDescription)
        }
    }
}
