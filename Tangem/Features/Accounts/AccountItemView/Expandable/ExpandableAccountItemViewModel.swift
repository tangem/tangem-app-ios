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
        iconData = AccountIconViewBuilder.makeAccountIconViewData(accountModel: accountModel)
        rawTokensCount = accountModel.userTokensManager.userTokens.count
        totalFiatBalance = accountModel.fiatTotalBalanceProvider.totalFiatBalance
        priceChange = priceChangeUtility.convertToPriceChangeState(
            changePercent: accountModel.rateProvider.accountRate.quote?.priceChange24h
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
                viewModel.priceChangeUtility.convertToPriceChangeState(changePercent: rate.quote?.priceChange24h)
            }
            .assign(to: &$priceChange)
    }

    private func onAccountModelDidChange() {
        name = accountModel.name
        iconData = AccountIconViewBuilder.makeAccountIconViewData(accountModel: accountModel)
    }
}
