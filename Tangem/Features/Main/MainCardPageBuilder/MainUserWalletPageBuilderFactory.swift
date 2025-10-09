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

        let referralNotificationController = CommonReferralNotificationController(userWalletModel: model)

        let userWalletNotificationManager = UserWalletNotificationManager(
            userWalletModel: model,
            rateAppController: rateAppController,
            referralNotificationController: referralNotificationController
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
            userWalletModel: model,
            coordinator: coordinator,
            yieldModuleNoticeInteractor: yieldModuleNoticeInteractor
        )

        if isMultiWalletPage {
            let optionsManager = OrganizeTokensOptionsManager(
                userTokensReorderer: model.userTokensManager
            )
            let sectionsAdapter = TokenSectionsAdapter(
                userTokenListManager: model.userTokenListManager,
                optionsProviding: optionsManager,
                preservesLastSortedOrderOnSwitchToDragAndDrop: false
            )
            let multiWalletNotificationManager = MultiWalletNotificationManager(
                userWalletId: model.userWalletId,
                totalBalanceProvider: model
            )

            let bannerNotificationManager: BannerNotificationManager? = {
                guard model.config.hasFeature(.multiCurrency) else {
                    return nil
                }

                return BannerNotificationManager(
                    userWallet: model,
                    placement: .main
                )
            }()

            let yieldModuleNotificationManager = WalletYieldNotificationManager(userWalletId: model.userWalletId)

            let viewModel = MultiWalletMainContentViewModel(
                userWalletModel: model,
                userWalletNotificationManager: userWalletNotificationManager,
                tokensNotificationManager: multiWalletNotificationManager,
                bannerNotificationManager: bannerNotificationManager,
                yieldModuleNotificationManager: yieldModuleNotificationManager,
                rateAppController: rateAppController,
                tokenSectionsAdapter: sectionsAdapter,
                tokenRouter: tokenRouter,
                optionsEditing: optionsManager,
                nftFeatureLifecycleHandler: nftLifecycleHandler,
                coordinator: coordinator
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

        guard let walletModel = model.walletModelsManager.walletModels.first else {
            return .singleWallet(id: id, headerModel: headerModel, bodyModel: nil)
        }

        let singleWalletNotificationManager = SingleTokenNotificationManager(
            userWalletId: model.userWalletId,
            walletModel: walletModel,
            walletModelsManager: model.walletModelsManager
        )

        let expressFactory = CommonExpressModulesFactory(
            inputModel: .init(userWalletModel: model, initialWalletModel: walletModel)
        )

        let pendingTransactionsManager = expressFactory.makePendingExpressTransactionsManager()

        let viewModel = SingleWalletMainContentViewModel(
            userWalletModel: model,
            walletModel: walletModel,
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
}
