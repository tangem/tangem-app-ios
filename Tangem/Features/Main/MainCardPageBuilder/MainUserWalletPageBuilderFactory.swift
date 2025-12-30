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
        NFTEntrypointRoutable

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

        let headerModel = MainHeaderViewModel(
            isUserWalletLocked: model.isUserWalletLocked,
            supplementInfoProvider: model,
            subtitleProvider: subtitleProvider,
            balanceProvider: balanceProvider,
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
                headerModel: headerModel,
                bodyModel: .init(
                    userWalletModel: model,
                    isMultiWallet: isMultiWalletPage,
                    lockedUserWalletDelegate: lockedUserWalletDelegate,
                    coordinator: coordinator
                )
            )
        }

        let yieldModuleNoticeInteractor = YieldModuleNoticeInteractor()

        let tokenRouter = SingleTokenRouter(
            userWalletInfo: model.userWalletInfo,
            coordinator: coordinator,
            yieldModuleNoticeInteractor: yieldModuleNoticeInteractor
        )

        if isMultiWalletPage {
            let multiWalletNotificationManager = MultiWalletNotificationManager(
                userWalletId: model.userWalletId,
                totalBalanceProvider: model
            )

            let bannerNotificationManager: BannerNotificationManager? = {
                guard model.config.hasFeature(.multiCurrency) else {
                    return nil
                }

                return BannerNotificationManager(userWalletInfo: model.userWalletInfo, placement: .main)
            }()

            let sectionsProvider = makeMultiWalletMainContentViewSectionsProvider(userWalletModel: model)

            let tokenItemPromoProvider = YieldTokenItemPromoProvider(
                userWalletModel: model,
                sectionsProvider: sectionsProvider,
                yieldModuleMarketsRepository: CommonYieldModuleMarketsRepository(),
                tokenItemPromoBubbleVisibilityInteractor: TokenItemPromoBubbleVisibilityInteractor()
            )

            let viewModel = MultiWalletMainContentViewModel(
                userWalletModel: model,
                userWalletNotificationManager: userWalletNotificationManager,
                sectionsProvider: sectionsProvider,
                tokensNotificationManager: multiWalletNotificationManager,
                bannerNotificationManager: bannerNotificationManager,
                rateAppController: rateAppController,
                nftFeatureLifecycleHandler: nftLifecycleHandler,
                tokenRouter: tokenRouter,
                coordinator: coordinator,
                tokenItemPromoProvider: tokenItemPromoProvider
            )
            viewModel.delegate = multiWalletContentDelegate
            userWalletNotificationManager.setupManager(with: viewModel)
            bannerNotificationManager?.setupManager(with: viewModel)

            return .multiWallet(
                id: id,
                headerModel: headerModel,
                bodyModel: viewModel
            )
        }

        guard let dependencies = makeSingleWalletDependencies(userWalletModel: model) else {
            return .singleWallet(id: id, headerModel: headerModel, bodyModel: nil)
        }

        let singleWalletNotificationManager = SingleTokenNotificationManager(
            userWalletId: model.userWalletId,
            walletModel: dependencies.walletModel,
            walletModelsManager: dependencies.walletModelsManager,
            tangemIconProvider: CommonTangemIconProvider(config: model.config)
        )

        let expressFactory = ExpressPendingTransactionsFactory(
            userWalletInfo: model.userWalletInfo,
            tokenItem: dependencies.walletModel.tokenItem,
            walletModelUpdater: dependencies.walletModel,
        )

        let pendingTransactionsManager = expressFactory.makePendingExpressTransactionsManager()

        let viewModel = SingleWalletMainContentViewModel(
            userWalletModel: model,
            walletModel: dependencies.walletModel,
            userWalletNotificationManager: userWalletNotificationManager,
            pendingExpressTransactionsManager: pendingTransactionsManager,
            tokenNotificationManager: singleWalletNotificationManager,
            rateAppController: rateAppController,
            tokenRouter: tokenRouter,
            delegate: singleWalletContentDelegate
        )
        userWalletNotificationManager.setupManager(with: viewModel)
        singleWalletNotificationManager.setupManager(with: viewModel)

        return .singleWallet(
            id: id,
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
        let headerModel = MainHeaderViewModel(
            isUserWalletLocked: visaUserWalletModel.isUserWalletLocked,
            supplementInfoProvider: visaUserWalletModel,
            subtitleProvider: subtitleProvider,
            balanceProvider: visaUserWalletModel,
            updatePublisher: visaUserWalletModel.updatePublisher
        )

        let viewModel = VisaWalletMainContentViewModel(
            visaWalletModel: visaUserWalletModel,
            coordinator: coordinator
        )

        if isUserWalletLocked {
            return .lockedWallet(
                id: id,
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
            headerModel: headerModel,
            bodyModel: viewModel
        )
    }

    private func makeMultiWalletMainContentViewSectionsProvider(
        userWalletModel: UserWalletModel
    ) -> any MultiWalletMainContentViewSectionsProvider {
        if FeatureProvider.isAvailable(.accounts) {
            return AccountsAwareMultiWalletMainContentViewSectionsProvider(userWalletModel: userWalletModel)
        }

        // accounts_fixes_needed_none
        let optionsManager = OrganizeTokensOptionsManager(
            userTokensReorderer: userWalletModel.userTokensManager
        )

        // accounts_fixes_needed_none
        let tokenSectionsAdapter = TokenSectionsAdapter(
            userTokensManager: userWalletModel.userTokensManager,
            optionsProviding: optionsManager,
            preservesLastSortedOrderOnSwitchToDragAndDrop: false
        )

        return LegacyMultiWalletMainContentViewSectionsProvider(
            userWalletModel: userWalletModel,
            optionsEditing: optionsManager,
            tokenSectionsAdapter: tokenSectionsAdapter
        )
    }

    private func makeSingleWalletDependencies(
        userWalletModel: UserWalletModel
    ) -> (walletModel: any WalletModel, walletModelsManager: WalletModelsManager)? {
        let walletModelsManager: WalletModelsManager

        if FeatureProvider.isAvailable(.accounts) {
            guard let mainAccount = userWalletModel.accountModelsManager.cryptoAccountModels.first(where: \.isMainAccount) else {
                return nil
            }
            walletModelsManager = mainAccount.walletModelsManager
        } else {
            // accounts_fixes_needed_none
            walletModelsManager = userWalletModel.walletModelsManager
        }

        guard let walletModel = walletModelsManager.walletModels.first else {
            return nil
        }

        return (walletModel: walletModel, walletModelsManager: walletModelsManager)
    }
}
