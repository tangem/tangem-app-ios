//
//  MainUserWalletPageBuilderFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemNFT
import TangemFoundation

protocol MainUserWalletPageBuilderFactory {
    func createPage(
        for model: UserWalletModel,
        lockedUserWalletDelegate: MainLockedUserWalletDelegate,
        singleWalletContentDelegate: SingleWalletMainContentDelegate,
        multiWalletContentDelegate: MultiWalletMainContentDelegate?,
        nftLifecycleHandler: NFTFeatureLifecycleHandling
    ) -> MainUserWalletPageBuilder

    func createPages(
        from models: [UserWalletModel],
        lockedUserWalletDelegate: MainLockedUserWalletDelegate,
        singleWalletContentDelegate: SingleWalletMainContentDelegate,
        multiWalletContentDelegate: MultiWalletMainContentDelegate?,
        nftLifecycleHandler: NFTFeatureLifecycleHandling
    ) -> [MainUserWalletPageBuilder]
}

struct CommonMainUserWalletPageBuilderFactory: MainUserWalletPageBuilderFactory {
    typealias MainContentRoutable = MultiWalletMainContentRoutable &
        VisaWalletRoutable &
        RateAppRoutable &
        ActionButtonsRoutable &
        NFTEntrypointRoutable &
        TokensManagementFlowRoutable

    @Injected(\.walletAssetsDiscoveryProgressProvider) private var walletAssetsDiscoveryProgressProvider: WalletAssetsDiscoveryProgressProvider
    @Injected(\.marketingCampaignsRepository) private var marketingCampaignsRepository: MarketingCampaignsRepository
    @Injected(\.promotionCampaignsRepository) private var promotionCampaignsRepository: PromotionCampaignsRepository
    @Injected(\.cryptoAccountsGlobalStateProvider) private var cryptoAccountsGlobalStateProvider: CryptoAccountsGlobalStateProvider

    weak var coordinator: MainContentRoutable?

    func createPage(
        for model: UserWalletModel,
        lockedUserWalletDelegate: MainLockedUserWalletDelegate,
        singleWalletContentDelegate: SingleWalletMainContentDelegate,
        multiWalletContentDelegate: MultiWalletMainContentDelegate?,
        nftLifecycleHandler: NFTFeatureLifecycleHandling
    ) -> MainUserWalletPageBuilder {
        if let visaUserWalletModel = model as? VisaUserWalletModel {
            return createVisaPage(visaUserWalletModel: visaUserWalletModel, lockedUserWalletDelegate: lockedUserWalletDelegate)
        }

        let id = model.userWalletId
        let containsDefaultToken = model.config.hasDefaultToken
        let isMultiWalletPage = model.config.hasFeature(.multiCurrency) || containsDefaultToken

        let providerFactory = model.config.makeMainHeaderProviderFactory()
        let balanceProvider = providerFactory.makeHeaderBalanceProvider(for: model)

        let navigationBalanceProvider = MainNavigationBalanceProvider(
            isUserWalletLocked: model.isUserWalletLocked,
            totalBalanceProvider: model
        )
        let navigationModel = MainNavigationViewModel(balanceProvider: navigationBalanceProvider)

        let headerModel = MainHeaderViewModel(
            userWalletId: model.userWalletId,
            isUserWalletLocked: model.isUserWalletLocked,
            walletThumbnailType: model.config.walletThumbnailType,
            supplementInfoProvider: model,
            balanceProvider: balanceProvider,
            walletAssetsDiscoveryProgressProvider: walletAssetsDiscoveryProgressProvider,
            updatePublisher: model.updatePublisher
        )

        let rateAppController = CommonRateAppController(
            userWalletModel: model,
            coordinator: coordinator
        )

        let userWalletNotificationManager = UserWalletNotificationManager(
            userWalletModel: model,
            rateAppController: rateAppController
        )

        if model.isUserWalletLocked {
            return .lockedWallet(
                id: id,
                navigationModel: navigationModel,
                headerModel: headerModel,
                bodyModel: .init(
                    userWalletModel: model,
                    isMultiWallet: isMultiWalletPage,
                    lockedUserWalletDelegate: lockedUserWalletDelegate,
                    coordinator: coordinator
                )
            )
        }

        marketingCampaignsRepository.loadCampaigns(for: .tokenDetails)
        marketingCampaignsRepository.loadCampaigns(for: .marketsToken)

        promotionCampaignsRepository.prewarm(userWalletId: model.userWalletId.stringValue)

        let tokenRouter = SingleTokenRouter(
            userWalletInfo: model.userWalletInfo,
            analyticsSource: .main,
            coordinator: coordinator
        )

        if isMultiWalletPage {
            let multiWalletNotificationManager = MultiWalletNotificationManager(
                userWalletId: model.userWalletId,
                totalBalanceProvider: model
            )

            let promotionNotificationsManager = CommonPromotionNotificationsManager(
                userWalletId: model.userWalletId,
                placement: .main
            )
            let tangemPayNotificationManager = TangemPayNotificationManager(userWalletModel: model)

            let getTangemPayBannerNotificationManager = GetTangemPayBannerNotificationManager(
                userWalletId: model.userWalletId.stringValue,
                tapAction: { [weak coordinator] availableSelection in
                    coordinator?.openGetTangemPay(availableSelection: availableSelection)
                    Analytics.log(.visaOnboardingVisaPermanentBannerClicked)
                }
            )

            let yieldApyBoostBannerNotificationManager = YieldAPYBoostBannerService(userWalletId: model.userWalletId)
            let forceUpdateBannerNotificationManager = ForceUpdateBannerNotificationManager()

            let tokenItemPromoProvider = YieldTokenItemPromoProvider(
                userWalletModel: model,
                yieldModuleMarketsRepository: CommonYieldModuleMarketsRepository(),
                tokenItemPromoBubbleVisibilityInteractor: TokenItemPromoBubbleVisibilityInteractor()
            )

            let sectionsProvider = makeMultiWalletMainContentViewSectionsProvider(userWalletModel: model)

            let mainNotificationsViewModel = MainNotificationsViewModel(
                isEnabled: FeatureProvider.isAvailable(.hideMarketingBannersWithSystem),
                promotionNotificationsManager: promotionNotificationsManager,
                // Order defines display priority — force-update banner renders above the rest.
                systemBannerItemsProvider: NotificationBannerItemsProvider(
                    managers: [
                        forceUpdateBannerNotificationManager,
                        userWalletNotificationManager,
                        yieldApyBoostBannerNotificationManager,
                        multiWalletNotificationManager,
                        tangemPayNotificationManager,
                    ]
                ),
                tangemPayPromoManager: getTangemPayBannerNotificationManager
            )

            let viewModel = MultiWalletMainContentViewModel(
                userWalletModel: model,
                userWalletNotificationManager: userWalletNotificationManager,
                sectionsProvider: sectionsProvider,
                tokensNotificationManager: multiWalletNotificationManager,
                promotionNotificationsManager: promotionNotificationsManager,
                tangemPayNotificationManager: tangemPayNotificationManager,
                yieldApyBoostBannerNotificationManager: yieldApyBoostBannerNotificationManager,
                forceUpdateBannerNotificationManager: forceUpdateBannerNotificationManager,
                rateAppController: rateAppController,
                nftFeatureLifecycleHandler: nftLifecycleHandler,
                tokenRouter: tokenRouter,
                coordinator: coordinator,
                tokenItemPromoProvider: tokenItemPromoProvider,
                mainNotificationsViewModel: mainNotificationsViewModel
            )
            viewModel.delegate = multiWalletContentDelegate
            userWalletNotificationManager.setupManager(with: viewModel)

            return .multiWallet(
                id: id,
                navigationModel: navigationModel,
                headerModel: headerModel,
                bodyModel: viewModel
            )
        }

        guard let dependencies = makeSingleWalletDependencies(userWalletModel: model) else {
            return .singleWallet(
                id: id,
                navigationModel: navigationModel,
                headerModel: headerModel,
                bodyModel: nil
            )
        }

        let singleWalletNotificationManager = SingleTokenNotificationManager(
            userWalletId: model.userWalletId,
            walletModel: dependencies.walletModel,
            walletModelsManager: dependencies.walletModelsManager,
            tangemIconProvider: CommonTangemIconProvider(config: model.config)
        )

        let promotionNotificationsManager = CommonPromotionNotificationsManager(
            userWalletId: model.userWalletId,
            placement: .main
        )

        let expressFactory = ExpressStatusTrackingFactory(
            userWalletInfo: model.userWalletInfo,
            tokenItem: dependencies.walletModel.tokenItem,
            transactionHistoryEnricherFactory: TransactionHistoryEnricherFactory.make(for: dependencies.walletModel)
        )

        let expressStatusTracking = expressFactory.makeExpressStatusTracking()

        let accountModel: (any CryptoAccountModel)? = {
            guard cryptoAccountsGlobalStateProvider.globalCryptoAccountsState() == .multiple else { return nil }
            return AccountModelsAggregator(.crypto).models(from: model.accountModelsManager).first(where: \.isMainAccount)
        }()

        let forceUpdateBannerNotificationManager = ForceUpdateBannerNotificationManager()

        let mainNotificationsViewModel = MainNotificationsViewModel(
            isEnabled: FeatureProvider.isAvailable(.hideMarketingBannersWithSystem),
            promotionNotificationsManager: promotionNotificationsManager,
            systemBannerItemsProvider: NotificationBannerItemsProvider(
                managers: [
                    forceUpdateBannerNotificationManager,
                    userWalletNotificationManager,
                ]
            ),
            tangemPayPromoManager: nil
        )

        let viewModel = SingleWalletMainContentViewModel(
            userWalletModel: model,
            walletModel: dependencies.walletModel,
            userWalletNotificationManager: userWalletNotificationManager,
            promotionNotificationsManager: promotionNotificationsManager,
            forceUpdateBannerNotificationManager: forceUpdateBannerNotificationManager,
            pendingExpressTransactionsManager: expressStatusTracking.manager,
            expressStatusPollingHelper: expressStatusTracking.pollingHelper,
            tokenNotificationManager: singleWalletNotificationManager,
            rateAppController: rateAppController,
            tokenRouter: tokenRouter,
            delegate: singleWalletContentDelegate,
            coordinator: coordinator,
            accountModel: accountModel,
            mainNotificationsViewModel: mainNotificationsViewModel
        )
        userWalletNotificationManager.setupManager(with: viewModel)
        singleWalletNotificationManager.setupManager(with: viewModel)

        return .singleWallet(
            id: id,
            navigationModel: navigationModel,
            headerModel: headerModel,
            bodyModel: viewModel
        )
    }

    func createPages(
        from models: [UserWalletModel],
        lockedUserWalletDelegate: MainLockedUserWalletDelegate,
        singleWalletContentDelegate: SingleWalletMainContentDelegate,
        multiWalletContentDelegate: MultiWalletMainContentDelegate?,
        nftLifecycleHandler: NFTFeatureLifecycleHandling
    ) -> [MainUserWalletPageBuilder] {
        models.map {
            createPage(
                for: $0,
                lockedUserWalletDelegate: lockedUserWalletDelegate,
                singleWalletContentDelegate: singleWalletContentDelegate,
                multiWalletContentDelegate: multiWalletContentDelegate,
                nftLifecycleHandler: nftLifecycleHandler
            )
        }
    }

    private func createVisaPage(visaUserWalletModel: VisaUserWalletModel, lockedUserWalletDelegate: MainLockedUserWalletDelegate?) -> MainUserWalletPageBuilder {
        let id = visaUserWalletModel.userWalletId
        let isUserWalletLocked = visaUserWalletModel.isUserWalletLocked

        let navigationBalanceProvider = MainNavigationBalanceProvider(
            isUserWalletLocked: visaUserWalletModel.isUserWalletLocked,
            totalBalanceProvider: visaUserWalletModel
        )
        let navigationModel = MainNavigationViewModel(balanceProvider: navigationBalanceProvider)

        let headerModel = MainHeaderViewModel(
            userWalletId: visaUserWalletModel.userWalletId,
            isUserWalletLocked: visaUserWalletModel.isUserWalletLocked,
            walletThumbnailType: visaUserWalletModel.config.walletThumbnailType,
            supplementInfoProvider: visaUserWalletModel,
            balanceProvider: visaUserWalletModel,
            walletAssetsDiscoveryProgressProvider: walletAssetsDiscoveryProgressProvider,
            updatePublisher: visaUserWalletModel.updatePublisher
        )

        let viewModel = VisaWalletMainContentViewModel(
            visaWalletModel: visaUserWalletModel,
            coordinator: coordinator
        )

        if isUserWalletLocked {
            return .lockedWallet(
                id: id,
                navigationModel: navigationModel,
                headerModel: headerModel,
                bodyModel: .init(
                    userWalletModel: visaUserWalletModel,
                    isMultiWallet: false,
                    lockedUserWalletDelegate: lockedUserWalletDelegate,
                    coordinator: coordinator
                )
            )
        }

        return .visaWallet(
            id: visaUserWalletModel.userWalletId,
            navigationModel: navigationModel,
            headerModel: headerModel,
            bodyModel: viewModel
        )
    }

    private func makeMultiWalletMainContentViewSectionsProvider(
        userWalletModel: UserWalletModel
    ) -> any MultiWalletMainContentViewSectionsProvider {
        return CommonMultiWalletMainContentViewSectionsProvider(
            userWalletModel: userWalletModel,
            manageTokensActionFactory: { [weak coordinator] account in
                { coordinator?.openManageTokens(for: account, in: userWalletModel) }
            }
        )
    }

    private func makeSingleWalletDependencies(
        userWalletModel: UserWalletModel
    ) -> (walletModel: any WalletModel, walletModelsManager: WalletModelsManager)? {
        guard let mainAccount = AccountModelsAggregator(.crypto).models(from: userWalletModel.accountModelsManager).first(where: \.isMainAccount) else {
            return nil
        }
        let walletModelsManager: WalletModelsManager = mainAccount.walletModelsManager

        guard let walletModel = walletModelsManager.walletModels.first else {
            return nil
        }

        return (walletModel: walletModel, walletModelsManager: walletModelsManager)
    }
}
