//
//  TokenDetailsEarnStateProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import BlockchainSdk
import TangemAssets
import TangemFoundation
import TangemLocalization
import TangemStaking
import TangemUI

final class TokenDetailsEarnStateProvider {
    private let walletModel: any WalletModel
    private let userWalletInfo: UserWalletInfo
    private weak var coordinator: (any TokenDetailsRoutable)?
    private let rateProvider: LendingRateProvider
    private let addFundsOptions: () -> [TokenDetailsActionsViewModel.AddFundsOption]
    private let openStaking: () -> Void
    private let balanceConverter = BalanceConverter()
    private let balanceFormatter = BalanceFormatter()
    private let lendingApy = CurrentValueSubject<LoadingResult<Decimal, Error>, Never>(.loading)
    private let lendingPosition = CurrentValueSubject<LoadingResult<Decimal, Never>, Never>(.loading)
    private let currentState = CurrentValueSubject<State?, Never>(nil)
    private let stateQueue = DispatchQueue(label: "com.tangem.TokenDetailsEarnStateProvider.state")
    private var lendingApyTask: Task<Void, Never>?
    private var lendingPositionTask: Task<Void, Never>?
    private var bag = Set<AnyCancellable>()

    init(
        walletModel: any WalletModel,
        userWalletInfo: UserWalletInfo,
        coordinator: (any TokenDetailsRoutable)?,
        rateProvider: LendingRateProvider = CommonLendingRateProvider(),
        addFundsOptions: @escaping () -> [TokenDetailsActionsViewModel.AddFundsOption],
        openStaking: @escaping () -> Void
    ) {
        self.walletModel = walletModel
        self.userWalletInfo = userWalletInfo
        self.coordinator = coordinator
        self.rateProvider = rateProvider
        self.addFundsOptions = addFundsOptions
        self.openStaking = openStaking
        bindState()
        loadLendingApy()
        bindLendingPosition()
    }

    deinit {
        lendingApyTask?.cancel()
        lendingPositionTask?.cancel()
    }

    var statePublisher: AnyPublisher<State, Never> {
        currentState
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }

    func refresh() {
        if case .failure = lendingApy.value {
            loadLendingApy()
        }

        loadLendingPosition()
    }

    func openLendingPosition() {
        guard let lendingModuleReader = walletModel.lendingModuleReader,
              let liquidityProvider = lendingModuleReader.liquidityProvider() else {
            return
        }

        let options = LendingPositionCoordinator.Options(
            token: CommonSendTransferableTokenFactory(userWalletInfo: userWalletInfo, walletModel: walletModel).makeTransferableToken(),
            currentApy: lendingApy.value.value,
            liquidityProvider: liquidityProvider,
            entryLoader: LendingDepositEntryLoader(reader: lendingModuleReader),
            pendingTransactions: walletModel.pendingTransactionPublisher
        )

        coordinator?.openLendingPosition(options: options)
    }
}

// MARK: - State

extension TokenDetailsEarnStateProvider {
    enum State {
        case earn(TokenDetailsStakingState)
        case staking(StakingManagerState)
    }
}

// MARK: - State mapping

private extension TokenDetailsEarnStateProvider {
    func state(
        staking: StakingManagerState,
        lendingApy: LoadingResult<Decimal, Error>,
        lendingPosition: LoadingResult<Decimal, Never>
    ) -> State {
        switch EthEarnProducts.banner(staking: earnStaking(from: staking), lendingApy: lendingApy, lendingPosition: lendingPosition) {
        case .none:
            return .staking(staking)
        case .loading:
            return .earn(.loading)
        case .earn(let products, let bestProduct):
            return .earn(makeEarnBannerState(products: products, bestProduct: bestProduct))
        case .yieldEnabled(let active, let inactive):
            return .earn(makeYieldEnabledState(active: active, inactive: inactive, staking: staking))
        }
    }

    func earnStaking(from staking: StakingManagerState) -> EthEarnProducts.Staking {
        switch staking {
        case .availableToStake(let info):
            return .available(apy: info.rewardRateValues.max)
        case .staked(let staked):
            return .staked(balance: staked.balances.stakes().sum(), apy: staking.apy ?? staked.yieldInfo.rewardRateValues.max)
        case .loading(let cached):
            return cachedStake(cached) ?? .loading
        case .loadingError(_, let cached), .unavailableInRegion(let cached), .temporaryUnavailable(_, let cached):
            return cachedStake(cached) ?? .unavailable
        case .notEnabled:
            return .unavailable
        }
    }

    func cachedStake(_ cached: CachedStakingManagerState?) -> EthEarnProducts.Staking? {
        guard let cached, case .staked(let balance) = cached.stakeState else {
            return nil
        }

        return .staked(balance: balance, apy: cached.apy)
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

    // [REDACTED_TODO_COMMENT]
    func makeYieldEnabledState(
        active: [EthEarnProducts.Position],
        inactive: [EarnYieldPickerProduct],
        staking: StakingManagerState
    ) -> TokenDetailsStakingState {
        let total = active.map(\.balance).reduce(0, +)
        let formattedTotal = balanceFormatter.formatCryptoBalance(total, currencyCode: walletModel.tokenItem.currencySymbol)

        let item = TokenDetailsStakingState.YieldEnabledItem(
            title: "Yield enabled",
            balance: formattedTotal,
            activeCount: "\(active.count) active",
            action: { [weak self] in
                self?.openEthYieldSheet(active: active, inactive: inactive, staking: staking)
            }
        )

        return .yieldEnabled(item: item)
    }
}

// MARK: - ETH yield sheet

private extension TokenDetailsEarnStateProvider {
    func openEthYieldSheet(active: [EthEarnProducts.Position], inactive: [EarnYieldPickerProduct], staking: StakingManagerState) {
        let viewModel = EthYieldSheetViewModel(
            activeRows: active.map { makeActiveYieldRow(position: $0, staking: staking) },
            inactiveRows: inactive.map { makeInactiveYieldRow(product: $0, products: inactive) }
        )

        coordinator?.openEthYieldSheet(viewModel)
    }

    // [REDACTED_TODO_COMMENT]
    func makeActiveYieldRow(position: EthEarnProducts.Position, staking: StakingManagerState) -> EthYieldSheetViewModel.RowItem {
        let percentFormatter = PercentFormatter()
        let rate = position.apy.map { apy in
            switch position.id {
            case .pooledStaking:
                "\(percentFormatter.format(apy, option: .earn)) APY"
            case .lendingOnAave:
                "\(percentFormatter.format(apy * (1 - LendingOnAave.performanceFee), option: .earn)) net APY"
            }
        }

        let fiat = walletModel.tokenItem.currencyId.flatMap { currencyId in
            balanceConverter.convertToFiat(position.balance, currencyId: currencyId)
        }

        return EthYieldSheetViewModel.RowItem(
            id: position.id,
            name: Self.yieldProductName(position.id),
            icon: Self.yieldProductIcon(position.id),
            content: .active(
                rate: rate,
                cryptoBalance: balanceFormatter.formatCryptoBalance(position.balance, currencyCode: walletModel.tokenItem.currencySymbol),
                fiatBalance: balanceFormatter.formatFiatBalance(fiat)
            ),
            action: { [weak self] in
                guard let self, let open = activeYieldDestination(of: position.id, staking: staking) else {
                    return
                }

                coordinator?.closeEthYieldSheet(then: open)
            }
        )
    }

    func activeYieldDestination(of id: EarnYieldPickerProduct.ID, staking: StakingManagerState) -> (() -> Void)? {
        switch id {
        case .lendingOnAave:
            return { [weak self] in self?.openLendingPosition() }
        case .pooledStaking:
            switch EthEarnProducts.stakingRoute(for: staking) {
            case .staking:
                return { [weak self] in self?.openStaking() }
            case .regionUnavailable:
                return { [weak self] in self?.coordinator?.openStakingRegionUnavailableSheet() }
            case .none:
                return nil
            }
        }
    }

    // [REDACTED_TODO_COMMENT]
    func makeInactiveYieldRow(product: EarnYieldPickerProduct, products: [EarnYieldPickerProduct]) -> EthYieldSheetViewModel.RowItem {
        EthYieldSheetViewModel.RowItem(
            id: product.id,
            name: product.name,
            icon: Self.yieldProductIcon(product.id),
            content: .inactive(rate: "\(PercentFormatter().format(product.apy, option: .earn)) APY", risk: "Low risk"),
            action: { [weak self] in
                self?.coordinator?.closeEthYieldSheet { [weak self] in
                    self?.openEarnYieldPicker(products: products, selectedProductID: product.id)
                }
            }
        )
    }

    // [REDACTED_TODO_COMMENT]
    static func yieldProductName(_ id: EarnYieldPickerProduct.ID) -> String {
        switch id {
        case .pooledStaking: "Pooled staking"
        case .lendingOnAave: "Lending on Aave"
        }
    }

    static func yieldProductIcon(_ id: EarnYieldPickerProduct.ID) -> EthYieldSheetViewModel.Icon {
        switch id {
        case .pooledStaking: .illustration(DesignSystem.Icons.accountStaking)
        case .lendingOnAave: .logo(Assets.YieldModule.yieldModuleAaveLogo)
        }
    }
}

// MARK: - Loading

private extension TokenDetailsEarnStateProvider {
    func bindState() {
        walletModel.stakingManagerStatePublisher
            .receive(on: stateQueue)
            .combineLatest(lendingApy.receive(on: stateQueue), lendingPosition.receive(on: stateQueue))
            .map { [weak self] staking, lendingApy, lendingPosition in
                self?.state(staking: staking, lendingApy: lendingApy, lendingPosition: lendingPosition) ?? .staking(staking)
            }
            .sink { [weak self] state in
                self?.currentState.send(state)
            }
            .store(in: &bag)
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

    func bindLendingPosition() {
        loadLendingPosition()

        walletModel.availableBalanceProvider
            .balanceTypePublisher
            .compactMap(\.value)
            .removeDuplicates()
            .dropFirst()
            .receiveOnMain()
            .sink { [weak self] _ in
                self?.loadLendingPosition()
            }
            .store(in: &bag)
    }

    func loadLendingPosition() {
        guard let liquidityProvider = walletModel.lendingModuleReader?.liquidityProvider() else {
            lendingPosition.send(.success(0))
            return
        }

        lendingPositionTask?.cancel()
        lendingPositionTask = Task { [weak self] in
            let position: Decimal?

            do {
                position = try await liquidityProvider.nativePosition()
            } catch is CancellationError {
                return
            } catch YieldModuleError.noYieldContractFound {
                position = 0
            } catch {
                AppLogger.error(error: error)
                position = nil
            }

            guard let self, !Task.isCancelled else { return }

            lendingPosition.send(.success(position ?? lendingPosition.value.value ?? 0))
        }
    }
}

// MARK: - Earn yield picker

private extension TokenDetailsEarnStateProvider {
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
