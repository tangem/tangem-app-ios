//
//  CommonBalancesViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import TangemAccessibilityIdentifiers

/// ViewModel for displaying all / available balances in the balance view.
final class CommonBalancesViewModel: BalancesViewModel {
    var isRefreshing: Bool { false }

    @Published var cryptoBalance: LoadableTokenBalanceView.State = .loading()
    @Published var fiatBalance: LoadableTokenBalanceView.State = .loading()

    var balanceAccessibilityIdentifier: String? {
        switch selectedBalanceType {
        case .all:
            return TokenAccessibilityIdentifiers.totalBalance
        case .available:
            return TokenAccessibilityIdentifiers.availableBalance
        }
    }

    var isYieldActive: Bool { false }

    @Published var balanceTypeValues: [BalanceWithButtonsViewModel.BalanceType]?
    @Published var selectedBalanceType: BalanceWithButtonsViewModel.BalanceType = .all

    private weak var balanceProvider: BalanceWithButtonsViewModelBalanceProvider?
    private weak var balanceTypeSelectorProvider: BalanceTypeSelectorProvider?

    private var bag = Set<AnyCancellable>()

    init(
        balanceProvider: BalanceWithButtonsViewModelBalanceProvider?,
        balanceTypeSelectorProvider: BalanceTypeSelectorProvider?,
    ) {
        self.balanceProvider = balanceProvider
        self.balanceTypeSelectorProvider = balanceTypeSelectorProvider

        bind()
    }

    private func bind() {
        balanceTypeSelectorProvider?.showBalanceSelectorPublisher
            .receiveOnMain()
            .map { show -> [BalanceWithButtonsViewModel.BalanceType]? in
                show ? BalanceWithButtonsViewModel.BalanceType.allCases : nil
            }
            .assign(to: &$balanceTypeValues)

        guard let balanceProvider else { return }
        Publishers
            .CombineLatest3(
                balanceProvider.totalFiatBalancePublisher,
                balanceProvider.availableFiatBalancePublisher,
                $selectedBalanceType
            )
            .receiveOnMain()
            .sink { [weak self] all, available, balanceType in
                guard let self else { return }
                setupBalance(
                    balance: &fiatBalance,
                    all: all,
                    available: available,
                    balanceType: balanceType,
                    isFiat: true
                )
            }
            .store(in: &bag)

        Publishers
            .CombineLatest3(
                balanceProvider.totalCryptoBalancePublisher,
                balanceProvider.availableCryptoBalancePublisher,
                $selectedBalanceType
            )
            .receiveOnMain()
            .sink { [weak self] all, available, balanceType in
                guard let self else { return }
                setupBalance(
                    balance: &cryptoBalance,
                    all: all,
                    available: available,
                    balanceType: balanceType,
                    isFiat: false
                )
            }
            .store(in: &bag)
    }

    private func setupBalance(
        balance: inout LoadableTokenBalanceView.State,
        all: FormattedTokenBalanceType,
        available: FormattedTokenBalanceType,
        balanceType: BalanceWithButtonsViewModel.BalanceType,
        isFiat: Bool
    ) {
        switch balance {
        case .loaded where all.isLoading || available.isLoading:
            break
        default:
            let builder = LoadableTokenBalanceViewStateBuilder()
            let result = if isFiat {
                builder.buildAttributedTotalBalance(type: balanceType == .all ? all : available)
            } else {
                builder.build(type: balanceType == .all ? all : available)
            }
            balance = result
        }
    }
}
