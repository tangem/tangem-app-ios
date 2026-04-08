//
//  TokenSelectorExpandableAccountItemViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemAccounts
import TangemLocalization
import TangemUI

final class TokenSelectorExpandableAccountItemViewModel: Identifiable, ObservableObject {
    // MARK: - View State

    @Published private(set) var isExpanded: Bool = false
    @Published private(set) var name: String
    @Published private(set) var iconData: AccountIconView.ViewData
    @Published private(set) var totalFiatBalance: LoadableBalanceView.State
    @Published private(set) var priceChange: PriceChangeView.State

    var tokensCount: String { Localization.commonTokensCount(rawTokensCount) }

    // MARK: - Private

    @Published private var rawTokensCount: Int

    private let accountModel: any BaseAccountModel
    private let priceChangeUtility = PriceChangeUtility()
    private let stateStorage: ExpandableAccountItemStateStorage

    /// User's explicit collapse/expand choice (independent of search override).
    private var userExplicitState: Bool = false
    private var isSearching: Bool = false
    private var bag: Set<AnyCancellable> = []
    private var didBind = false

    // MARK: - Init

    init(
        account: any BaseAccountModel,
        stateStorage: ExpandableAccountItemStateStorage,
        initialItemsCount: Int = 0,
        itemsCountPublisher: AnyPublisher<Int, Never>,
        searchTextPublisher: AnyPublisher<String, Never>
    ) {
        accountModel = account
        self.stateStorage = stateStorage
        name = account.name
        iconData = AccountModelUtils.UI.iconViewData(accountModel: account)
        rawTokensCount = initialItemsCount

        let initialExpanded = stateStorage.isExpanded(account)
        isExpanded = initialExpanded
        userExplicitState = initialExpanded

        // Try to get balance/rate from BalanceProvidingAccountModel
        if let balanceProvider = account as? BalanceProvidingAccountModel {
            totalFiatBalance = balanceProvider.fiatTotalBalanceProvider.totalFiatBalance
            priceChange = Self.mapToPriceChangeState(
                rate: balanceProvider.rateProvider.accountRate,
                using: priceChangeUtility
            )
        } else {
            totalFiatBalance = .empty
            priceChange = .noData
        }

        bindItemsCount(itemsCountPublisher)
        bindSearchText(searchTextPublisher)
    }

    // MARK: - Internal

    func onViewAppear() {
        bindAccountModel()
    }

    func onExpandedChange(_ isExpanded: Bool) {
        guard !isSearching else { return }

        userExplicitState = isExpanded
        stateStorage.setIsExpanded(isExpanded, for: accountModel)
        self.isExpanded = isExpanded
    }

    // MARK: - Private

    private func bindItemsCount(_ publisher: AnyPublisher<Int, Never>) {
        publisher
            .receiveOnMain()
            .assign(to: &$rawTokensCount)
    }

    private func bindSearchText(_ publisher: AnyPublisher<String, Never>) {
        publisher
            .map { !$0.trimmed().isEmpty }
            .removeDuplicates()
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, isSearching in
                viewModel.isSearching = isSearching
                if isSearching {
                    viewModel.isExpanded = true
                } else {
                    viewModel.isExpanded = viewModel.userExplicitState
                }
            }
            .store(in: &bag)
    }

    private func bindAccountModel() {
        guard !didBind else { return }
        didBind = true

        accountModel
            .didChangePublisher
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, _ in
                viewModel.name = viewModel.accountModel.name
                viewModel.iconData = AccountModelUtils.UI.iconViewData(accountModel: viewModel.accountModel)
            }
            .store(in: &bag)

        guard let balanceProvider = accountModel as? BalanceProvidingAccountModel else { return }

        balanceProvider
            .fiatTotalBalanceProvider
            .totalFiatBalancePublisher
            .receiveOnMain()
            .assign(to: &$totalFiatBalance)

        balanceProvider
            .rateProvider
            .accountRatePublisher
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .map { viewModel, rate in
                Self.mapToPriceChangeState(rate: rate, using: viewModel.priceChangeUtility)
            }
            .assign(to: &$priceChange)
    }

    private static func mapToPriceChangeState(
        rate: RateValue<AccountQuote>,
        using priceChangeUtility: PriceChangeUtility
    ) -> PriceChangeView.State {
        switch rate {
        case .loading(.none):
            return .loading

        case .loading(.some(let quote)),
             .failure(.some(let quote)),
             .loaded(let quote):
            return priceChangeUtility.convertToPriceChangeState(changePercent: quote.priceChange24h)

        case .custom, .failure(.none):
            return .noData
        }
    }
}
