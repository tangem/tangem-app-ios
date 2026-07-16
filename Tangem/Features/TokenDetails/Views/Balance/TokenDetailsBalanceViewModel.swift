//
//  TokenDetailsBalanceViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemAssets
import TangemUI
import TangemLocalization

final class TokenDetailsBalanceViewModel: ObservableObject {
    typealias Text = SensitiveText.TextType

    @Published private(set) var state: State = .common
    @Published private(set) var balanceMode: BalanceMode = .total

    @Published private(set) var fiatBalanceState: TokenDetailsBalanceState = .loading
    @Published private(set) var cryptoBalanceState: TokenDetailsBalanceState = .loading

    @Published private var hasAvailableBalance: Bool = false

    let tokenIconInfo: TokenIconInfo

    var canChangeBalanceMode: Bool {
        state == .common && hasAvailableBalance
    }

    private let reloadBalance: () -> Void
    private let balanceTicker: YieldBalanceTicker

    private weak var dataProvider: TokenDetailsBalanceDataProvider?

    private var commonStateBag = Set<AnyCancellable>()
    private var yieldStateBag = Set<AnyCancellable>()
    private var bag = Set<AnyCancellable>()

    init(
        tokenItem: TokenItem,
        dataProvider: TokenDetailsBalanceDataProvider,
        reloadBalance: @escaping () -> Void
    ) {
        self.dataProvider = dataProvider
        self.reloadBalance = reloadBalance

        tokenIconInfo = TokenIconInfoBuilder().build(
            from: tokenItem,
            isCustom: dataProvider.isTokenCustom
        )

        balanceTicker = YieldBalanceTicker(
            tokenItem: tokenItem,
            initialCryptoBalance: nil,
            apy: nil
        )

        bind()
    }
}

// MARK: - Internal methods

extension TokenDetailsBalanceViewModel {
    func onBalancePickerTap() {
        toggleBalanceMode()
    }
}

// MARK: - Bindings

private extension TokenDetailsBalanceViewModel {
    func bind() {
        dataProvider?.yieldModuleState
            .map { $0.state.isEffectivelyActive && $0.marketInfo != nil }
            .removeDuplicates()
            .map { isActive in
                isActive ? .yield : .common
            }
            .receiveOnMain()
            .assign(to: &$state)

        $state
            .withWeakCaptureOf(self)
            .sink { viewModel, state in
                viewModel.cleanStates()
                switch state {
                case .common:
                    viewModel.bindCommonState()
                case .yield:
                    viewModel.bindYieldState()
                }
            }
            .store(in: &bag)

        dataProvider?.stakingBalanceTypePublisher
            .withWeakCaptureOf(self)
            .map { viewModel, balanceType in
                viewModel.hasAvailableBalance(balanceType: balanceType)
            }
            .receiveOnMain()
            .assign(to: &$hasAvailableBalance)
    }

    func bindCommonState() {
        guard let dataProvider else { return }

        Publishers.CombineLatest3(
            dataProvider.totalFiatBalancePublisher,
            dataProvider.availableFiatBalancePublisher,
            $balanceMode
        )
        .compactMap { [weak self] totalFiatBalance, availableFiatBalance, balanceMode in
            switch balanceMode {
            case .total:
                self?.balanceState(balanceType: totalFiatBalance, balanceKind: .fiat)
            case .available:
                self?.balanceState(balanceType: availableFiatBalance, balanceKind: .fiat)
            }
        }
        .withWeakCaptureOf(self)
        .receiveOnMain()
        .sink { viewModel, state in
            viewModel.fiatBalanceState = state
        }
        .store(in: &commonStateBag)

        Publishers.CombineLatest3(
            dataProvider.totalCryptoBalancePublisher,
            dataProvider.availableCryptoBalancePublisher,
            $balanceMode
        )
        .compactMap { [weak self] totalFiatBalance, availableFiatBalance, balanceMode in
            switch balanceMode {
            case .total:
                self?.balanceState(balanceType: totalFiatBalance, balanceKind: .crypto)
            case .available:
                self?.balanceState(balanceType: availableFiatBalance, balanceKind: .crypto)
            }
        }
        .withWeakCaptureOf(self)
        .receiveOnMain()
        .sink { viewModel, state in
            viewModel.cryptoBalanceState = state
        }
        .store(in: &commonStateBag)
    }

    func bindYieldState() {
        dataProvider?.yieldModuleState
            .removeDuplicates { current, updated in
                let isBalanceUnchanged = current.state.activeInfo?.balance == updated.state.activeInfo?.balance
                let isApyUnchanged = current.marketInfo?.apy == updated.marketInfo?.apy
                return isBalanceUnchanged && isApyUnchanged
            }
            .withWeakCaptureOf(self)
            .sink { viewModel, stateInfo in
                viewModel.updateYieldBalanceTickerIfNeeded(stateInfo: stateInfo)
            }
            .store(in: &yieldStateBag)

        balanceTicker.currentCryptoBalancePublisher
            .withWeakCaptureOf(self)
            .receiveOnMain()
            .sink { viewModel, formattedBalance in
                let balanceState = viewModel.balanceState(
                    balanceType: .loaded(formattedBalance),
                    balanceKind: .crypto
                )
                viewModel.cryptoBalanceState = balanceState
            }
            .store(in: &yieldStateBag)

        balanceTicker.currentFiatBalancePublisher
            .withWeakCaptureOf(self)
            .receiveOnMain()
            .sink { viewModel, formattedBalance in
                let balanceState = viewModel.balanceState(
                    balanceType: .loaded(formattedBalance),
                    balanceKind: .fiat
                )
                viewModel.fiatBalanceState = balanceState
            }
            .store(in: &yieldStateBag)

        reloadBalance()
    }
}

// MARK: - BalanceState

private extension TokenDetailsBalanceViewModel {
    func balanceState(
        balanceType: FormattedTokenBalanceType,
        balanceKind: BalanceKind
    ) -> TokenDetailsBalanceState {
        let hasLoadingBalance = hasLoadingBalance(balanceType: balanceType)
        let hasBalance = hasBalance(balanceType: balanceType)
        let attributedBalance = attributedBalance(balanceType.value, kind: balanceKind)

        if hasLoadingBalance {
            if hasBalance {
                return .loadingCached(attributedBalance)
            } else {
                return .loading
            }
        } else {
            if hasBalance {
                let hasFailedBalance = hasFailedBalance(balanceType: balanceType)

                if hasFailedBalance {
                    return .failed(attributedBalance)
                } else {
                    return .loaded(attributedBalance)
                }
            } else {
                return .failed(attributedBalance)
            }
        }
    }

    func attributedBalance(_ balance: String, kind: BalanceKind) -> Text {
        switch kind {
        case .crypto: attributedCryptoBalance(balance)
        case .fiat: attributedFiatBalance(balance)
        }
    }

    func attributedFiatBalance(_ balance: String) -> Text {
        let attributedBalance = AttributedBalanceFormatter.format(
            balance,
            font: Font.Tangem.Title44.semibold,
            integerColor: .Tangem.Text.Neutral.primary,
            fractionalColor: .Tangem.Text.Neutral.secondary
        )
        return .attributed(attributedBalance)
    }

    func attributedCryptoBalance(_ balance: String) -> Text {
        let attributedBalance = AttributedBalanceFormatter.format(
            balance,
            font: Font.Tangem.Body16.medium,
            integerColor: .Tangem.Text.Neutral.secondary,
            fractionalColor: .Tangem.Text.Neutral.secondary
        )
        return .attributed(attributedBalance)
    }
}

// MARK: - Yield BalanceTicker

private extension TokenDetailsBalanceViewModel {
    func updateYieldBalanceTickerIfNeeded(stateInfo: YieldModuleManagerStateInfo) {
        guard
            let yieldSupplyInfo = stateInfo.state.activeInfo,
            let apy = stateInfo.marketInfo?.apy
        else {
            return
        }

        let balance = yieldSupplyInfo.balance.value
        balanceTicker.updateCurrentBalance(balance, apy: apy)
    }
}

// MARK: - Private methods

private extension TokenDetailsBalanceViewModel {
    func hasLoadingBalance(balanceType: FormattedTokenBalanceType) -> Bool {
        balanceType.isLoading
    }

    func hasFailedBalance(balanceType: FormattedTokenBalanceType) -> Bool {
        balanceType.isFailure
    }

    func hasBalance(balanceType: FormattedTokenBalanceType) -> Bool {
        switch balanceType {
        case .loaded: true
        case .loading(let cached): cached.isCache
        case .failure(let cached): cached.isCache
        }
    }

    func hasAvailableBalance(balanceType: TokenBalanceType) -> Bool {
        switch balanceType {
        case .empty:
            return false
        case .loaded(let amount) where amount == .zero:
            return false
        case .failure(let cached) where hasZeroOrNil(cached: cached):
            return false
        case .loading(let cached) where hasZeroOrNil(cached: cached):
            return false
        case .failure, .loading, .loaded:
            return true
        }
    }

    func hasZeroOrNil(cached: TokenBalanceType.Cached?) -> Bool {
        cached?.balance == .zero || cached == nil
    }

    func cleanStates() {
        fiatBalanceState = .loading
        cryptoBalanceState = .loading
        commonStateBag.removeAll()
        yieldStateBag.removeAll()
    }

    func toggleBalanceMode() {
        let changedMode: BalanceMode = switch balanceMode {
        case .total: .available
        case .available: .total
        }
        balanceMode = changedMode
    }
}

// MARK: - Types

extension TokenDetailsBalanceViewModel {
    enum State {
        case common
        case yield
    }

    enum BalanceMode {
        case total
        case available

        var title: String {
            switch self {
            case .total: return Localization.tokenDetailsBalanceTotal
            case .available: return Localization.tokenDetailsBalanceAvailable
            }
        }
    }

    enum BalanceKind {
        case crypto
        case fiat
    }
}
