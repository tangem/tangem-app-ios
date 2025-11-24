//
//  BalanceWithButtonsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
import SwiftUI

enum BalancesState {
    case common(viewModel: CommonBalancesViewModel)
    case yield(viewModel: YieldBalancesViewModel)
}

final class BalanceWithButtonsViewModel: ObservableObject, Identifiable {
    @Published var state: BalancesState?

    @Published var buttons: [FixedSizeButtonWithIconInfo] = []

    private let tokenItem: TokenItem
    private let buttonsPublisher: AnyPublisher<[FixedSizeButtonWithIconInfo], Never>
    private weak var balanceProvider: BalanceWithButtonsViewModelBalanceProvider?
    private weak var balanceTypeSelectorProvider: BalanceTypeSelectorProvider?
    private weak var yieldModuleStatusProvider: YieldModuleStatusProvider?
    private(set) var showYieldBalanceInfoAction: () -> Void
    private(set) var reloadBalance: () async -> Void

    private var bag = Set<AnyCancellable>()

    init(
        tokenItem: TokenItem,
        buttonsPublisher: AnyPublisher<[FixedSizeButtonWithIconInfo], Never>,
        balanceProvider: BalanceWithButtonsViewModelBalanceProvider,
        balanceTypeSelectorProvider: BalanceTypeSelectorProvider,
        yieldModuleStatusProvider: YieldModuleStatusProvider,
        showYieldBalanceInfoAction: @escaping (() -> Void),
        reloadBalance: @escaping (() async -> Void)
    ) {
        self.tokenItem = tokenItem
        self.buttonsPublisher = buttonsPublisher
        self.balanceProvider = balanceProvider
        self.balanceTypeSelectorProvider = balanceTypeSelectorProvider
        self.showYieldBalanceInfoAction = showYieldBalanceInfoAction
        self.yieldModuleStatusProvider = yieldModuleStatusProvider
        self.reloadBalance = reloadBalance

        bind()
    }

    private func bind() {
        buttonsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] buttons in
                self?.buttons = buttons
            }
            .store(in: &bag)

        guard let yieldModuleStatusProvider else {
            setupCommonBalances()
            return
        }

        yieldModuleStatusProvider
            .yieldModuleState
            .filter { !$0.state.isLoading }
            .receiveOnMain()
            .map { $0.state.isEffectivelyActive && $0.marketInfo != nil }
            .removeDuplicates()
            .sink { [weak self] isActive in
                if isActive {
                    self?.setupYieldBalances()
                } else {
                    self?.setupCommonBalances()
                }
            }
            .store(in: &bag)
    }

    private func setupCommonBalances() {
        guard let balanceProvider, let balanceTypeSelectorProvider else { return }
        state = .common(
            viewModel: CommonBalancesViewModel(
                balanceProvider: balanceProvider,
                balanceTypeSelectorProvider: balanceTypeSelectorProvider
            )
        )
    }

    private func setupYieldBalances() {
        guard let balanceProvider else { return }

        state = .yield(
            viewModel: YieldBalancesViewModel(
                tokenItem: tokenItem,
                balanceProvider: balanceProvider,
                yieldModuleStatusProvider: yieldModuleStatusProvider,
                showYieldBalanceInfoAction: showYieldBalanceInfoAction,
                reloadBalance: reloadBalance
            )
        )
    }
}
