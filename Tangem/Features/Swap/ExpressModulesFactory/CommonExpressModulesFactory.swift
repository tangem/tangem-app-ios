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

    @Injected(\.tangemApiService)
    private var tangemApiService: TangemApiService

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
        // Create external search view model if feature toggle is enabled
        let marketsTokensViewModel: SwapMarketsTokensViewModel?
        if FeatureProvider.isAvailable(.expressAllTokensSearch) {
            marketsTokensViewModel = SwapMarketsTokensViewModel(
                searchProvider: CommonSwapMarketsSearchTokensProvider(tangemApiService: tangemApiService)
            )
        } else {
            marketsTokensViewModel = nil
        }

        return SwapTokenSelectorViewModel(
            swapDirection: swapDirection,
            tokenSelectorViewModel: AccountsAwareTokenSelectorViewModel(
                walletsProvider: .common(),
                availabilityProvider: .swap()
            ),
            marketsTokensViewModel: marketsTokensViewModel,
            expressInteractor: expressDependenciesFactory.expressInteractor,
            tangemApiService: tangemApiService,
            coordinator: coordinator
        )
    }

    func makeFeeSelectorViewModel(coordinator: SendFeeSelectorRoutable) -> SendFeeSelectorViewModel? {
        guard let source = expressDependenciesFactory.expressInteractor.getSource().value else {
            return nil
        }

        let builder = SendFeeSelectorBuilder(
            tokenFeeManagerProviding: expressDependenciesFactory.expressInteractor,
            feeSelectorOutput: expressDependenciesFactory.expressInteractor,
            analyticsLogger: source.interactorAnalyticsLogger,
        )

        return builder.makeSendFeeSelector(router: coordinator)
    }

    func makeExpressApproveViewModel(
        source: any ExpressInteractorSourceWallet,
        providerName: String,
        selectedPolicy: BSDKApprovePolicy,
        coordinator: ExpressApproveRoutable
    ) -> ExpressApproveViewModel {
        let tokenItem = source.tokenItem

        return ExpressApproveViewModel(
            input: .init(
                settings: .init(
                    subtitle: Localization.givePermissionSwapSubtitle(providerName, tokenItem.currencySymbol),
                    feeFooterText: Localization.swapGivePermissionFeeFooter,
                    tokenItem: tokenItem,
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
