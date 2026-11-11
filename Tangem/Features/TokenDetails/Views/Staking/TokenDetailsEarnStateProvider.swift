//
//  TokenDetailsEarnStateProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation
import TangemLocalization
import TangemStaking

final class TokenDetailsEarnStateProvider {
    private let walletModel: any WalletModel
    private let userWalletInfo: UserWalletInfo
    private weak var coordinator: (any TokenDetailsRoutable)?
    private let rateProvider: LendingRateProvider
    private let addFundsOptions: () -> [TokenDetailsActionsViewModel.AddFundsOption]
    private let lendingApy = CurrentValueSubject<LoadingResult<Decimal, Error>, Never>(.loading)
    private var lendingApyTask: Task<Void, Never>?

    init(
        walletModel: any WalletModel,
        userWalletInfo: UserWalletInfo,
        coordinator: (any TokenDetailsRoutable)?,
        rateProvider: LendingRateProvider = CommonLendingRateProvider(),
        addFundsOptions: @escaping () -> [TokenDetailsActionsViewModel.AddFundsOption]
    ) {
        self.walletModel = walletModel
        self.userWalletInfo = userWalletInfo
        self.coordinator = coordinator
        self.rateProvider = rateProvider
        self.addFundsOptions = addFundsOptions
        loadLendingApy()
    }

    deinit {
        lendingApyTask?.cancel()
    }

    var statePublisher: AnyPublisher<State, Never> {
        walletModel.stakingManagerStatePublisher
            .combineLatest(lendingApy)
            .map { [weak self] staking, lendingApy in
                self?.state(staking: staking, lendingApy: lendingApy) ?? .staking(staking)
            }
            .eraseToAnyPublisher()
    }

    func refresh() {
        guard case .failure = lendingApy.value else {
            return
        }

        loadLendingApy()
    }
}

// MARK: - State

extension TokenDetailsEarnStateProvider {
    enum State {
        case earn(TokenDetailsStakingState)
        case staking(StakingManagerState)
    }
}

// MARK: - Private

private extension TokenDetailsEarnStateProvider {
    func state(staking: StakingManagerState, lendingApy: LoadingResult<Decimal, Error>) -> State {
        switch EthEarnProducts.banner(staking: earnStaking(from: staking), lendingApy: lendingApy) {
        case .none:
            return .staking(staking)
        case .loading:
            return .earn(.loading)
        case .earn(let products, let bestProduct):
            return .earn(makeEarnBannerState(products: products, bestProduct: bestProduct))
        }
    }

    func earnStaking(from staking: StakingManagerState) -> EthEarnProducts.Staking {
        switch staking {
        case .availableToStake(let info):
            return .available(apy: info.rewardRateValues.max)
        case .staked:
            return .staked
        case .loading(let cached):
            return hasStake(cached) ? .staked : .loading
        case .loadingError(_, let cached), .unavailableInRegion(let cached), .temporaryUnavailable(_, let cached):
            return hasStake(cached) ? .staked : .unavailable
        case .notEnabled:
            return .unavailable
        }
    }

    func hasStake(_ cached: CachedStakingManagerState?) -> Bool {
        if case .staked = cached?.stakeState {
            return true
        }

        return false
    }

    func makeEarnBannerState(products: [EarnYieldPickerProduct], bestProduct: EarnYieldPickerProduct) -> TokenDetailsStakingState {
        // [REDACTED_TODO_COMMENT]
        let item = TokenDetailsStakingState.AvailableItem(
            title: "Earn",
            description: Localization.tokenDetailsEarnStakingSubtitleApy(PercentFormatter().format(bestProduct.apy, option: .earn)),
            actionTitle: Localization.commonEnable,
            action: { [weak self] in
                self?.openEarnYieldPicker(products: products, selectedProductID: bestProduct.id)
            }
        )

        return .earn(item: item)
    }

    func loadLendingApy() {
        let rateProvider = rateProvider

        lendingApyTask?.cancel()
        lendingApyTask = Task { [weak self] in
            let apy: LoadingResult<Decimal, Error>

            do {
                let value = try await rateProvider.currentApy()
                apy = .success(value)
            } catch {
                AppLogger.error(error: error)
                apy = .failure(error)
            }

            guard !Task.isCancelled else { return }

            self?.lendingApy.send(apy)
        }
    }

    func openEarnYieldPicker(products: [EarnYieldPickerProduct], selectedProductID: EarnYieldPickerProduct.ID) {
        guard let lendingModuleReader = walletModel.lendingModuleReader else {
            return
        }

        let options = EarnYieldPickerCoordinator.Options(
            products: products,
            selectedProductID: selectedProductID,
            balanceProvider: walletModel.availableBalanceProvider,
            currencyCode: AppSettings.shared.selectedCurrencyCode,
            lendingToken: CommonSendTransferableTokenFactory(userWalletInfo: userWalletInfo, walletModel: walletModel).makeTransferableToken(),
            lendingEntryLoader: LendingDepositEntryLoader(reader: lendingModuleReader),
            addFundsOptions: addFundsOptions
        )

        coordinator?.openEarnYieldPicker(options: options)
    }
}
