//
//  DependenciesFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import TangemExpress
import BlockchainSdk

class CommonExpressModulesFactory {
    @Injected(\.expressPendingTransactionsRepository)
    private var pendingTransactionRepository: ExpressPendingTransactionRepository

    @Injected(\.expressPairsRepository)
    private var expressPairsRepository: ExpressPairsRepository

    private let userWalletInfo: UserWalletInfo
    private let initialSourceWallet: any ExpressInteractorSourceWallet
    private let expressDependenciesFactory: ExpressDependenciesFactory

    // MARK: - Internal

    private let priceChangeFormatter: PriceChangeFormatter = .init()
    private let balanceConverter: BalanceConverter = .init()
    private let balanceFormatter: BalanceFormatter = .init()

    private lazy var feeFormatter: FeeFormatter = CommonFeeFormatter(
        balanceFormatter: balanceFormatter,
        balanceConverter: balanceConverter
    )

    private lazy var expressProviderFormatter = ExpressProviderFormatter(
        balanceFormatter: balanceFormatter
    )

    init(input: ExpressDependenciesInput) {
        userWalletInfo = input.userWalletInfo
        initialSourceWallet = input.source

        expressDependenciesFactory = CommonExpressDependenciesFactory(
            input: input,
            supportedProviderTypes: .swap,
            operationType: .swap
        )
    }
}

// MARK: - ExpressModulesFactory

extension CommonExpressModulesFactory: ExpressModulesFactory {
    func makeExpressViewModel(coordinator: ExpressRoutable) -> ExpressViewModel {
        let notificationManager = ExpressNotificationManager(
            userWalletId: userWalletInfo.id,
            expressInteractor: expressDependenciesFactory.expressInteractor
        )

        let model = ExpressViewModel(
            userWalletInfo: userWalletInfo,
            initialTokenItem: initialSourceWallet.tokenItem,
            feeFormatter: feeFormatter,
            balanceFormatter: balanceFormatter,
            expressProviderFormatter: expressProviderFormatter,
            notificationManager: notificationManager,
            expressRepository: expressDependenciesFactory.expressRepository,
            interactor: expressDependenciesFactory.expressInteractor,
            coordinator: coordinator
        )
        notificationManager.setupManager(with: model)
        return model
    }

    func makeExpressTokensListViewModel(
        swapDirection: ExpressTokensListViewModel.SwapDirection,
        coordinator: ExpressTokensListRoutable
    ) -> ExpressTokensListViewModel {
        ExpressTokensListViewModel(
            swapDirection: swapDirection,
            expressTokensListAdapter: CommonExpressTokensListAdapter(userWalletId: userWalletInfo.id),
            expressPairsRepository: expressPairsRepository,
            expressInteractor: expressDependenciesFactory.expressInteractor,
            coordinator: coordinator,
            userWalletModelConfig: userWalletInfo.config
        )
    }

    func makeSwapTokenSelectorViewModel(
        swapDirection: SwapTokenSelectorViewModel.SwapDirection,
        coordinator: any SwapTokenSelectorRoutable
    ) -> SwapTokenSelectorViewModel {
        SwapTokenSelectorViewModel(
            swapDirection: swapDirection,
            expressPairsRepository: expressPairsRepository,
            expressInteractor: expressDependenciesFactory.expressInteractor,
            coordinator: coordinator
        )
    }

    func makeExpressFeeSelectorViewModel(coordinator: ExpressFeeSelectorRoutable) -> ExpressFeeSelectorViewModel {
        ExpressFeeSelectorViewModel(
            feeFormatter: feeFormatter,
            expressInteractor: expressDependenciesFactory.expressInteractor,
            coordinator: coordinator
        )
    }

    func makeExpressApproveViewModel(
        providerName: String,
        selectedPolicy: BSDKApprovePolicy,
        coordinator: ExpressApproveRoutable
    ) -> ExpressApproveViewModel {
        let tokenItem = expressDependenciesFactory.expressInteractor.getSender().tokenItem

        return ExpressApproveViewModel(
            settings: .init(
                subtitle: Localization.givePermissionSwapSubtitle(providerName, tokenItem.currencySymbol),
                feeFooterText: Localization.swapGivePermissionFeeFooter,
                tokenItem: tokenItem,
                feeTokenItem: expressDependenciesFactory.expressInteractor.getSender().feeTokenItem,
                selectedPolicy: selectedPolicy
            ),
            feeFormatter: feeFormatter,
            approveViewModelInput: expressDependenciesFactory.expressInteractor,
            coordinator: coordinator
        )
    }

    func makeExpressProvidersSelectorViewModel(
        coordinator: ExpressProvidersSelectorRoutable
    ) -> ExpressProvidersSelectorViewModel {
        ExpressProvidersSelectorViewModel(
            priceChangeFormatter: priceChangeFormatter,
            expressProviderFormatter: expressProviderFormatter,
            expressRepository: expressDependenciesFactory.expressRepository,
            expressInteractor: expressDependenciesFactory.expressInteractor,
            coordinator: coordinator
        )
    }

    func makeExpressSuccessSentViewModel(data: SentExpressTransactionData, coordinator: ExpressSuccessSentRoutable) -> ExpressSuccessSentViewModel {
        ExpressSuccessSentViewModel(
            data: data,
            initialTokenItem: initialSourceWallet.tokenItem,
            balanceConverter: balanceConverter,
            balanceFormatter: balanceFormatter,
            providerFormatter: ExpressProviderFormatter(balanceFormatter: balanceFormatter),
            feeFormatter: feeFormatter,
            coordinator: coordinator
        )
    }
}

// MARK: Dependencies

private extension CommonExpressModulesFactory {
    /// Be careful to use tokenItem in CommonExpressAnalyticsLogger
    /// Becase there will be inly initial tokenItem without updating
    var analyticsLogger: ExpressAnalyticsLogger {
        CommonExpressAnalyticsLogger(tokenItem: initialSourceWallet.tokenItem)
    }
}
