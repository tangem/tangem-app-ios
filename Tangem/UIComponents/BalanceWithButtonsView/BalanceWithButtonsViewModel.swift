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
import TangemMacro

enum BalancesState {
    case common(viewModel: CommonBalancesViewModel)
    case yield(viewModel: YieldBalancesViewModel)
}

final class BalanceWithButtonsViewModel: ObservableObject, Identifiable {
    @Published var state: BalancesState?

    @Published var balanceTypeValues: [BalanceType]?
    @Published var selectedBalanceType: BalanceType = .all

    @Published var buttons: [FixedSizeButtonWithIconInfo] = []

    private let tokenItem: TokenItem
    private let buttonsPublisher: AnyPublisher<[FixedSizeButtonWithIconInfo], Never>
    private var isRefresing = false
    private weak var balanceProvider: BalanceWithButtonsViewModelBalanceProvider?
    private weak var balanceTypeSelectorProvider: BalanceTypeSelectorProvider?
    private weak var yieldModuleStatusProvider: YieldModuleStatusProvider?
    private weak var refreshStatusProvider: RefreshStatusProvider?
    private(set) var showYieldBalanceInfoAction: () -> Void
    private(set) var reloadBalance: () async -> Void

    private var bag = Set<AnyCancellable>()

    init(
        tokenItem: TokenItem,
        buttonsPublisher: AnyPublisher<[FixedSizeButtonWithIconInfo], Never>,
        balanceProvider: BalanceWithButtonsViewModelBalanceProvider,
        balanceTypeSelectorProvider: BalanceTypeSelectorProvider,
        yieldModuleStatusProvider: YieldModuleStatusProvider,
        refreshStatusProvider: RefreshStatusProvider,
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

        self.refreshStatusProvider = refreshStatusProvider

        setupCommonBalances()

        bind()
    }

    private func bind() {
        buttonsPublisher
            .receiveOnMain()
            .sink { [weak self] buttons in
                self?.buttons = buttons
            }
            .store(in: &bag)

        refreshStatusProvider?.isRefreshing
            .receiveOnMain()
            .sink { [weak self] isRefreshing in
                self?.isRefresing = isRefreshing
            }
            .store(in: &bag)

        guard let yieldModuleStatusProvider else {
            return
        }

        yieldModuleStatusProvider
            .yieldModuleState
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

        if case .common = state { // could be already set up
            return
        }

        let viewModel = CommonBalancesViewModel(
            balanceProvider: balanceProvider,
            balanceTypeSelectorProvider: balanceTypeSelectorProvider
        )

        // setup two-way bindings with child viewModel
        $balanceTypeValues
            .removeDuplicates() // breaks infinite loop
            .assign(to: \.balanceTypeValues, on: viewModel, ownership: .weak)
            .store(in: &bag)

        $selectedBalanceType
            .removeDuplicates() // breaks infinite loop
            .assign(to: \.selectedBalanceType, on: viewModel, ownership: .weak)
            .store(in: &bag)

        viewModel.$balanceTypeValues
            .assign(to: &$balanceTypeValues)

        viewModel.$selectedBalanceType
            .assign(to: &$selectedBalanceType)

        state = .common(
            viewModel: viewModel
        )
    }

    private func setupYieldBalances() {
        state = .yield(
            viewModel: YieldBalancesViewModel(
                tokenItem: tokenItem,
                yieldModuleStatusProvider: yieldModuleStatusProvider,
                refreshStatusProvider: refreshStatusProvider,
                showYieldBalanceInfoAction: showYieldBalanceInfoAction,
                reloadBalance: reloadBalance
            )
        )
    }
}

extension BalanceWithButtonsViewModel {
    @RawCaseName
    enum BalanceType: String, CaseIterable, Hashable, Identifiable {
        case all
        case available

        var title: String {
            rawValue.capitalized
        }
    }
}
