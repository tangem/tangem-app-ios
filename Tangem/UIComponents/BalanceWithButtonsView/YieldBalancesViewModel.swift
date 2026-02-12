//
//  YieldBalancesViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import TangemUI

/// ViewModel for displaying yield balances in the balance view.
/// It manages the loading and formatting of both crypto and fiat yield balances.
/// It also handles the ticks of yield balances based on the current APY.
final class YieldBalancesViewModel: BalancesViewModel {
    @Published var cryptoBalance: LoadableBalanceView.State = .loading()
    @Published var fiatBalance: LoadableBalanceView.State = .loading()
    @Published var isRefreshing: Bool = false

    var balanceAccessibilityIdentifier: String? { nil }
    var isYieldActive: Bool { true }

    private let tokenItem: TokenItem

    private weak var yieldModuleStatusProvider: YieldModuleStatusProvider?
    private weak var refreshStatusProvider: RefreshStatusProvider?

    private(set) var showYieldBalanceInfoAction: () -> Void
    private(set) var reloadBalance: () async -> Void

    private var balanceTicker: YieldBalanceTicker?

    private var bag = Set<AnyCancellable>()

    init(
        tokenItem: TokenItem,
        yieldModuleStatusProvider: YieldModuleStatusProvider?,
        refreshStatusProvider: RefreshStatusProvider?,
        showYieldBalanceInfoAction: @escaping () -> Void,
        reloadBalance: @escaping () async -> Void
    ) {
        self.tokenItem = tokenItem
        self.yieldModuleStatusProvider = yieldModuleStatusProvider
        self.showYieldBalanceInfoAction = showYieldBalanceInfoAction
        self.refreshStatusProvider = refreshStatusProvider
        self.reloadBalance = reloadBalance

        bind()
        triggerReloadBalance()
    }

    private func bind() {
        refreshStatusProvider?.isRefreshing
            .dropFirst()
            .removeDuplicates()
            .flatMap { isRefreshing in
                Just(isRefreshing).delay(for: isRefreshing ? .zero : .seconds(0.7), scheduler: DispatchQueue.main)
            }
            .receiveOnMain()
            .sink { [weak self] in
                self?.isRefreshing = $0
            }
            .store(in: &bag)

        yieldModuleStatusProvider?
            .yieldModuleState
            .receiveOnMain()
            .removeDuplicates(by: { old, new in
                let balanceUnchanged = old.state.activeInfo?.balance == new.state.activeInfo?.balance
                let apyUnchanged = old.marketInfo?.apy == new.marketInfo?.apy
                return balanceUnchanged && apyUnchanged
            })
            .sink { [weak self] stateInfo in
                guard let yieldSupplyInfo = stateInfo.state.activeInfo,
                      let apy = stateInfo.marketInfo?.apy else { return }
                self?.updateYieldBalanceTicker(yieldBalance: yieldSupplyInfo.balance.value, apy: apy)
            }
            .store(in: &bag)
    }

    private func triggerReloadBalance() {
        // trigger loading state
        setupBalance(balance: &cryptoBalance, balanceType: .loading(.empty("")), isFiat: false)
        setupBalance(balance: &fiatBalance, balanceType: .loading(.empty("")), isFiat: true)

        Task { @MainActor [weak self] in
            // start ticker with updated balance
            if let reloadBalance = self?.reloadBalance {
                await reloadBalance()
            }
        }
    }

    private func updateYieldBalanceTicker(yieldBalance: Decimal, apy: Decimal) {
        switch balanceTicker {
        case .some(let ticker):
            ticker.updateCurrentBalance(yieldBalance, apy: apy)
        case .none:
            balanceTicker = YieldBalanceTicker(tokenItem: tokenItem, initialCryptoBalance: yieldBalance, apy: apy)
            bindYieldBalanceTicker(bag: &bag)
        }
    }

    private func bindYieldBalanceTicker(bag: inout Set<AnyCancellable>) {
        balanceTicker?.currentCryptoBalancePublisher
            .compactMap { $0 }
            .receiveOnMain()
            .sink { [weak self] formattedBalance in
                guard let self else { return }
                setupBalance(balance: &cryptoBalance, balanceType: .loaded(formattedBalance), isFiat: false)
            }
            .store(in: &bag)

        balanceTicker?.currentFiatBalancePublisher
            .compactMap { $0 }
            .receiveOnMain()
            .sink { [weak self] formattedBalance in
                guard let self else { return }
                setupBalance(balance: &fiatBalance, balanceType: .loaded(formattedBalance), isFiat: true)
            }
            .store(in: &bag)
    }

    private func setupBalance(
        balance: inout LoadableBalanceView.State,
        balanceType: FormattedTokenBalanceType,
        isFiat: Bool
    ) {
        let builder = LoadableBalanceViewStateBuilder()
        balance = if isFiat {
            builder.buildAttributedTotalBalance(type: balanceType)
        } else {
            builder.build(type: balanceType)
        }
    }
}
