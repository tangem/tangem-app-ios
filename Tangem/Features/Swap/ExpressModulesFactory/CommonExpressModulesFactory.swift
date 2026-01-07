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
    private let initialTokenItem: TokenItem
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
        initialTokenItem = input.source.tokenItem

        expressDependenciesFactory = CommonExpressDependenciesFactory(input: input)
    }

    init(input: ExpressDependenciesDestinationInput) {
        userWalletInfo = input.userWalletInfo
        initialTokenItem = input.destination.tokenItem

        expressDependenciesFactory = CommonExpressDependenciesFactory(input: input)
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
            initialTokenItem: initialTokenItem,
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
            userWalletInfo: userWalletInfo
        )
    }

    func makeSwapTokenSelectorViewModel(
        swapDirection: SwapTokenSelectorViewModel.SwapDirection,
        coordinator: any SwapTokenSelectorRoutable
    ) -> SwapTokenSelectorViewModel {
        SwapTokenSelectorViewModel(
            swapDirection: swapDirection,
            tokenSelectorViewModel: AccountsAwareTokenSelectorViewModel(walletsProvider: .common(), availabilityProvider: .swap()),
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

    func makeFeeSelectorViewModel(coordinator: FeeSelectorRoutable) -> SendFeeSelectorViewModel {
        let feeSelectorViewModel = FeeSelectorBuilder().makeFeeSelectorViewModel(
            feeSelectorInteractor: expressDependenciesFactory.expressInteractor.feeSelectorInteractor,
            mapper: CommonFeeSelectorFeesViewModelMapper(feeFormatter: CommonFeeFormatter()),
            analytics: ExpressFeeSelectorAnalytics(),
            router: coordinator
        )

        return SendFeeSelectorViewModel(feeSelectorViewModel: feeSelectorViewModel)
    }

    func makeExpressApproveViewModel(
        source: any ExpressInteractorSourceWallet,
        providerName: String,
        selectedPolicy: BSDKApprovePolicy,
        coordinator: ExpressApproveRoutable
    ) -> ExpressApproveViewModel {
        let tokenItem = source.tokenItem
        let feeTokenItem = source.feeTokenItem

        return ExpressApproveViewModel(
            input: .init(
                settings: .init(
                    subtitle: Localization.givePermissionSwapSubtitle(providerName, tokenItem.currencySymbol),
                    feeFooterText: Localization.swapGivePermissionFeeFooter,
                    tokenItem: tokenItem,
                    feeTokenItem: feeTokenItem,
                    selectedPolicy: selectedPolicy,
                    tangemIconProvider: CommonTangemIconProvider(config: userWalletInfo.config)
                ),
                feeFormatter: feeFormatter,
                approveViewModelInput: expressDependenciesFactory.expressInteractor,
            ),
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
            initialTokenItem: initialTokenItem,
            balanceConverter: balanceConverter,
            balanceFormatter: balanceFormatter,
            providerFormatter: ExpressProviderFormatter(balanceFormatter: balanceFormatter),
            feeFormatter: feeFormatter,
            coordinator: coordinator
        )
    }
}
