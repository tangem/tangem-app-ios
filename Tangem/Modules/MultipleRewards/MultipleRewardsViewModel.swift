//
//  MultipleRewardsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import TangemStaking
import SwiftUI

final class MultipleRewardsViewModel: ObservableObject, Identifiable {
    // MARK: - ViewState

    @Published var validators: [ValidatorViewData] = []
    @Published var actionSheet: ActionSheetBinder?

    // MARK: - Dependencies

    private let tokenItem: TokenItem
    private let stakingManager: StakingManager
    private weak var coordinator: MultipleRewardsRoutable?

    private let percentFormatter = PercentFormatter()
    private let balanceFormatter = BalanceFormatter()
    private let balanceConverter = BalanceConverter()

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
                        viewModel.mapToValidatorViewData(yield: staked.yieldInfo, balance: balance)
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

    func mapToValidatorViewData(yield: YieldInfo, balance: StakingBalanceInfo) -> ValidatorViewData? {
        guard let validator = yield.validators.first(where: { $0.address == balance.validatorAddress }) else {
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

        let subtitleType: ValidatorViewData.SubtitleType? = validator.apr.map {
            .active(apr: percentFormatter.format($0, option: .staking))
        }

        return ValidatorViewData(
            address: validator.address,
            name: validator.name,
            imageURL: validator.iconURL,
            subtitleType: subtitleType,
            detailsType: .balance(
                BalanceInfo(balance: balanceCryptoFormatted, fiatBalance: balanceFiatFormatted),
                action: { [weak self] in
                    self?.openUnstakingFlow(balance: balance)
                }
            )
        )
    }

    func openUnstakingFlow(balance: StakingBalanceInfo) {
        switch PendingActionMapper(balanceInfo: balance).getAction() {
        case .none:
            break
        case .single(let action):
            coordinator?.openUnstakingFlow(action: action)
        case .multiple(let actions):
            var buttons: [Alert.Button] = actions.map { action in
                .default(Text(action.type.title)) { [weak self] in
                    self?.coordinator?.openUnstakingFlow(action: action)
                }
            }

            buttons.append(.cancel())
            actionSheet = .init(sheet: .init(title: Text(Localization.commonSelectAction), buttons: buttons))
        }
    }
}
