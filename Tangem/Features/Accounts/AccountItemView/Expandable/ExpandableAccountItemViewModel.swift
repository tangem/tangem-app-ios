//
//  ExpandableAccountItemViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemAccounts
import TangemLocalization

final class ExpandableAccountItemViewModel: Identifiable, ObservableObject {
    // MARK: - View State

    @Published private(set) var name: String
    @Published private(set) var iconData: AccountIconView.ViewData
    @Published private(set) var totalFiatBalance: LoadableTokenBalanceView.State
    @Published private(set) var priceChange: TokenPriceChangeView.State

    var tokensCount: String { Localization.commonTokensCount(rawTokensCount) }
    var isEmptyContent: Bool { rawTokensCount == 0 }

    // MARK: - Private properties

    @Published private var rawTokensCount: Int

    private let accountModel: any CryptoAccountModel
    private let priceChangeUtility: PriceChangeUtility

    private var bag: Set<AnyCancellable> = []
    private var didBind = false

    init(
        accountModel: any CryptoAccountModel
    ) {
        self.accountModel = accountModel

        let priceChangeUtility = PriceChangeUtility()
        self.priceChangeUtility = priceChangeUtility

        name = accountModel.name
        iconData = AccountModelUtils.UI.iconViewData(accountModel: accountModel)
        rawTokensCount = accountModel.userTokensManager.userTokens.count
        totalFiatBalance = accountModel.fiatTotalBalanceProvider.totalFiatBalance
        priceChange = Self.mapToPriceChangeState(
            rate: accountModel.rateProvider.accountRate,
            using: priceChangeUtility
        )
    }

    func onViewAppear() {
        bind()
    }

    private func bind() {
        if didBind {
            return
        }

        didBind = true

        accountModel
            .didChangePublisher
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, _ in
                viewModel.onAccountModelDidChange()
            }
            .store(in: &bag)

        accountModel
            .userTokensManager
            .userTokensPublisher
            .map(\.count)
            .assign(to: &$rawTokensCount)

        accountModel
            .fiatTotalBalanceProvider
            .totalFiatBalancePublisher
            .receiveOnMain()
            .assign(to: &$totalFiatBalance)

        accountModel
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
    ) -> TokenPriceChangeView.State {
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

    private func onAccountModelDidChange() {
        name = accountModel.name
        iconData = AccountModelUtils.UI.iconViewData(accountModel: accountModel)
    }
}
