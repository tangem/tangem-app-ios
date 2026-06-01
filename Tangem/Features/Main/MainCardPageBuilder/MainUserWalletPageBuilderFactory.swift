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
        let subtitleProvider = providerFactory.makeHeaderSubtitleProvider(for: model, isMultiWallet: isMultiWalletPage)

        let navigationBalanceProvider = CommonMainNavigationBalanceProvider(
            isUserWalletLocked: model.isUserWalletLocked,
            totalBalanceProvider: model
        )
        let navigationModel = MainNavigationViewModel(balanceProvider: navigationBalanceProvider)

        let headerModel = MainHeaderViewModel(
            userWalletId: model.userWalletId,
            isUserWalletLocked: model.isUserWalletLocked,
            walletThumbnailType: model.config.walletThumbnailType,
            supplementInfoProvider: model,
            subtitleProvider: subtitleProvider,
            balanceProvider: balanceProvider,
            walletAssetsDiscoveryProgressProvider: walletAssetsDiscoveryProgressProvider,
            updatePublisher: model.updatePublisher
        )

        let rateAppController = CommonRateAppController(
            rateAppService: RateAppService(),
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

        let tokenRouter = SingleTokenRouter(
            userWalletInfo: model.userWalletInfo,
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

            let tokenItemPromoProvider = YieldTokenItemPromoProvider(
                userWalletModel: model,
                yieldModuleMarketsRepository: CommonYieldModuleMarketsRepository(),
                tokenItemPromoBubbleVisibilityInteractor: TokenItemPromoBubbleVisibilityInteractor()
            )

            let sectionsProvider = makeMultiWalletMainContentViewSectionsProvider(userWalletModel: model)

            let viewModel = MultiWalletMainContentViewModel(
                userWalletModel: model,
                userWalletNotificationManager: userWalletNotificationManager,
                sectionsProvider: sectionsProvider,
                tokensNotificationManager: multiWalletNotificationManager,
                promotionNotificationsManager: promotionNotificationsManager,
                tangemPayNotificationManager: tangemPayNotificationManager,
                getTangemPayBannerNotificationManager: getTangemPayBannerNotificationManager,
                yieldApyBoostBannerNotificationManager: yieldApyBoostBannerNotificationManager,
                rateAppController: rateAppController,
                nftFeatureLifecycleHandler: nftLifecycleHandler,
                tokenRouter: tokenRouter,
                coordinator: coordinator,
                tokenItemPromoProvider: tokenItemPromoProvider
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

        let expressFactory = ExpressPendingTransactionsFactory(
            userWalletInfo: model.userWalletInfo,
            tokenItem: dependencies.walletModel.tokenItem,
            walletModelUpdater: dependencies.walletModel,
        )

        let pendingTransactionsManager = expressFactory.makePendingExpressTransactionsManager()

        let accountModel: (any CryptoAccountModel)? = {
            let cryptoAccounts = model.accountModelsManager.accountModels.cryptoAccounts()
            guard cryptoAccounts.hasMultipleAccounts else { return nil }
            return model.accountModelsManager.cryptoAccountModels.first(where: \.isMainAccount)
        }()

        let viewModel = SingleWalletMainContentViewModel(
            userWalletModel: model,
            walletModel: dependencies.walletModel,
            userWalletNotificationManager: userWalletNotificationManager,
            promotionNotificationsManager: promotionNotificationsManager,
            pendingExpressTransactionsManager: pendingTransactionsManager,
            tokenNotificationManager: singleWalletNotificationManager,
            rateAppController: rateAppController,
            tokenRouter: tokenRouter,
            delegate: singleWalletContentDelegate,
            coordinator: coordinator,
            accountModel: accountModel
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
        return models.compactMap {
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

        let subtitleProvider = VisaWalletMainHeaderSubtitleProvider(isUserWalletLocked: isUserWalletLocked, dataSource: visaUserWalletModel)

        let navigationBalanceProvider = CommonMainNavigationBalanceProvider(
            isUserWalletLocked: visaUserWalletModel.isUserWalletLocked,
            totalBalanceProvider: visaUserWalletModel
        )
        let navigationModel = MainNavigationViewModel(balanceProvider: navigationBalanceProvider)

        let headerModel = MainHeaderViewModel(
            userWalletId: visaUserWalletModel.userWalletId,
            isUserWalletLocked: visaUserWalletModel.isUserWalletLocked,
            walletThumbnailType: visaUserWalletModel.config.walletThumbnailType,
            supplementInfoProvider: visaUserWalletModel,
            subtitleProvider: subtitleProvider,
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
        guard let mainAccount = userWalletModel.accountModelsManager.cryptoAccountModels.first(where: \.isMainAccount) else {
            return nil
        }
        let walletModelsManager: WalletModelsManager = mainAccount.walletModelsManager

        guard let walletModel = walletModelsManager.walletModels.first else {
            return nil
        }

        return (walletModel: walletModel, walletModelsManager: walletModelsManager)
    }
}
