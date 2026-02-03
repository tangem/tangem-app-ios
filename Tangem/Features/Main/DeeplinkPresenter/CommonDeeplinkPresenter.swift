//
//  CommonDeeplinkPresenter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets

final class CommonDeeplinkPresenter {
    typealias DeepLinkDestination = MainCoordinator.DeepLinkDestination

    // MARK: - Properties

    @Injected(\.overlayContentStateController) private var bottomSheetStateController: OverlayContentStateController
    @Injected(\.incomingActionManager) private var incomingActionManager: IncomingActionManaging
    @Injected(\.mainBottomSheetUIManager) private var mainBottomSheetUIManager: MainBottomSheetUIManager

    private let coordinatorFactory: MainCoordinatorChildFactory

    // MARK: - Init

    init(coordinatorFactory: MainCoordinatorChildFactory) {
        self.coordinatorFactory = coordinatorFactory
    }
}

// MARK: - Deeplink Presenter

extension CommonDeeplinkPresenter: DeeplinkPresenter {
    public func present(deepLink: DeepLinkDestination) {
        if case .market = deepLink {
            expandMarketsBottomSheetIfPossible()
            return
        }

        guard let viewController = constructViewControllerForDeepLink(deepLink) else {
            return
        }

        var shouldAnimate: Bool {
            if case .promo = deepLink {
                return false
            }

            return true
        }

        AppPresenter.shared.show(viewController, animated: shouldAnimate)
    }
}

// MARK: - Private Implementation

private extension CommonDeeplinkPresenter {
    func makeDeeplinkViewController<Content: View>(
        @ViewBuilder view: () -> Content,
        embedInNavigationStack: Bool,
        modalPresentationStyle: UIModalPresentationStyle = .automatic
    ) -> UIViewController {
        let controller: UIViewController
        if embedInNavigationStack {
            let navRoot = NavigationStack {
                view()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button(Localization.commonClose) {
                                UIApplication.dismissTop()
                            }
                            .foregroundColor(Colors.Text.primary1)
                        }
                    }
            }
            controller = UIHostingController(rootView: navRoot)
        } else {
            controller = UIHostingController(rootView: view())
        }
        controller.modalPresentationStyle = modalPresentationStyle

        return controller
    }
}

private extension CommonDeeplinkPresenter {
    private func constructViewControllerForDeepLink(_ deepLink: DeepLinkDestination) -> UIViewController? {
        switch deepLink {
        case .expressTransactionStatus(let walletModel, let userWalletModel, let pendingTransactionDetails):
            return constructTokenDetailsViewController(
                walletModel: walletModel,
                userWalletModel: userWalletModel,
                pendingTransactionDetails: pendingTransactionDetails
            )

        case .tokenDetails(let walletModel, let userWalletModel):
            return constructTokenDetailsViewController(
                walletModel: walletModel,
                userWalletModel: userWalletModel,
                pendingTransactionDetails: nil
            )

        case .buy(let userWalletModel):
            return constructBuyViewController(userWalletModel: userWalletModel)

        case .sell(let userWalletModel):
            return constructSellViewController(userWalletModel: userWalletModel)

        case .swap(let userWalletModel):
            return constructSwapViewController(userWalletModel: userWalletModel)

        case .referral(let input):
            return constructReferralViewController(input: input)

        case .staking(let options):
            return constructStakingViewController(options: options)

        case .marketsTokenDetails(let tokenId):
            return constructMarketsTokenViewController(tokenId: tokenId)

        case .onboardVisa(let deeplinkString):
            return constructTangemPayOnboardViewController(
                deeplinkString: deeplinkString,
            )

        case .promo(let promoCode, let refcode, let campaign):
            return constructPromoViewController(promoCode: promoCode, refcode: refcode, campaign: campaign)

        case .newsDetails(let newsId):
            return constructNewsDetailsViewController(newsId: newsId)

        case .externalLink, .market:
            return nil
        }
    }
}

private extension CommonDeeplinkPresenter {
    private func constructPromoViewController(promoCode: String, refcode: String?, campaign: String?) -> UIViewController {
        let viewController = makeDeeplinkViewController(
            view: { PromocodeActivationView(promoCode: promoCode, refcode: refcode, campaign: campaign) },
            embedInNavigationStack: false
        )

        viewController.view.backgroundColor = .clear
        viewController.modalPresentationStyle = .overFullScreen

        return viewController
    }

    private func constructTokenDetailsViewController(
        walletModel: any WalletModel,
        userWalletModel: UserWalletModel,
        pendingTransactionDetails: PendingTransactionDetails?
    ) -> UIViewController? {
        let coordinator = coordinatorFactory.makeTokenDetailsCoordinator(dismissAction: { UIApplication.dismissTop() })

        // [REDACTED_TODO_COMMENT]
        if FeatureProvider.isAvailable(.accounts) {
            guard let account = walletModel.account else {
                let message = "Inconsistent state: WalletModel '\(walletModel.name)' has no account in accounts-enabled build"
                AppLogger.error(error: message)
                assertionFailure(message)
                return nil
            }

            coordinator.start(
                with: .init(
                    userWalletInfo: userWalletModel.userWalletInfo,
                    keysDerivingInteractor: userWalletModel.keysDerivingInteractor,
                    walletModelsManager: account.walletModelsManager,
                    userTokensManager: account.userTokensManager,
                    walletModel: walletModel,
                    pendingTransactionDetails: pendingTransactionDetails
                )
            )
        } else {
            coordinator.start(
                with: .init(
                    userWalletInfo: userWalletModel.userWalletInfo,
                    keysDerivingInteractor: userWalletModel.keysDerivingInteractor,
                    walletModelsManager: userWalletModel.walletModelsManager,
                    userTokensManager: userWalletModel.userTokensManager,
                    walletModel: walletModel,
                    pendingTransactionDetails: pendingTransactionDetails
                )
            )
        }

        return makeDeeplinkViewController(
            view: { TokenDetailsCoordinatorView(coordinator: coordinator) },
            embedInNavigationStack: true
        )
    }

    private func constructReferralViewController(input: ReferralInputModel) -> UIViewController {
        let coordinator = coordinatorFactory.makeReferralCoordinator(dismissAction: { UIApplication.dismissTop() })

        coordinator.start(with: .init(input: input))
        return makeDeeplinkViewController(
            view: { ReferralCoordinatorView(coordinator: coordinator) },
            embedInNavigationStack: true
        )
    }

    private func constructBuyViewController(userWalletModel: UserWalletModel) -> UIViewController {
        let coordinator = coordinatorFactory.makeBuyCoordinator(dismissAction: { UIApplication.dismissTop() })

        coordinator.start(
            with: .default(
                options: .init(
                    userWalletModel: userWalletModel,
                    expressTokensListAdapter: CommonExpressTokensListAdapter(userWalletId: userWalletModel.userWalletId),
                    tokenSorter: CommonBuyTokenAvailabilitySorter(userWalletModelConfig: userWalletModel.config)
                )
            )
        )

        return makeDeeplinkViewController(
            view: { ActionButtonsBuyCoordinatorView(coordinator: coordinator) },
            embedInNavigationStack: false
        )
    }

    private func constructSellViewController(userWalletModel: UserWalletModel) -> UIViewController {
        let coordinator = coordinatorFactory.makeSellCoordinator(
            userWalletModel: userWalletModel,
            dismissAction: { _ in UIApplication.dismissTop() }
        )

        coordinator.start(with: .default)
        return makeDeeplinkViewController(
            view: { ActionButtonsSellCoordinatorView(coordinator: coordinator) },
            embedInNavigationStack: false
        )
    }

    private func constructSwapViewController(userWalletModel: UserWalletModel) -> UIViewController {
        let coordinator = coordinatorFactory.makeSwapCoordinator(
            userWalletModel: userWalletModel,
            dismissAction: { _ in UIApplication.dismissTop() }
        )

        coordinator.start(with: .default)
        return makeDeeplinkViewController(
            view: { ActionButtonsSwapCoordinatorView(coordinator: coordinator) },
            embedInNavigationStack: false
        )
    }

    private func constructStakingViewController(options: StakingDetailsCoordinator.Options) -> UIViewController {
        let coordinator = coordinatorFactory.makeStakingCoordinator(
            dismissAction: { UIApplication.dismissTop() },
            popToRootAction: { _ in }
        )

        coordinator.start(with: options)
        return makeDeeplinkViewController(
            view: { StakingDetailsCoordinatorView(coordinator: coordinator) },
            embedInNavigationStack: true
        )
    }

    private func constructMarketsTokenViewController(tokenId: String) -> UIViewController {
        // When token details are opened, any missing data will be fetched from the API.
        let tokenModel = MarketsTokenModel(
            id: tokenId,
            name: "",
            symbol: "",
            currentPrice: nil,
            priceChangePercentage: [:],
            marketRating: nil,
            maxYieldApy: nil,
            marketCap: nil,
            isUnderMarketCapLimit: nil,
            stakingOpportunities: nil
        )

        let coordinator = coordinatorFactory.makeMarketsTokenDetailsCoordinator()
        coordinator.start(with: .init(info: tokenModel, style: .defaultNavigationStack))

        // When opening MarketsTokenDetailsView via deeplink (using UIKit via AppPresenter.show method),
        // the new SwiftUI view hierarchy doesn't inherit the original Environment values.
        // Since some views inside MarketsTokenDetailsCoordinatorView rely on environment value `.mainWindowSize`
        // for layout calculations, we manually inject the current window size here.
        var windowSize: CGSize?

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            windowSize = window.screen.bounds.size
        }

        return makeDeeplinkViewController(
            view: {
                MarketsTokenDetailsCoordinatorView(coordinator: coordinator)
                    .environment(\.mainWindowSize, windowSize ?? .zero)
            },
            embedInNavigationStack: true
        )
    }

    private func constructTangemPayOnboardViewController(
        deeplinkString: String
    ) -> UIViewController {
        let coordinator = coordinatorFactory.makeTangemPayOnboardingCoordinator { _ in
            UIApplication.dismissTop()
        }
        coordinator.start(with: .init(source: .deeplink(deeplinkString)))

        return makeDeeplinkViewController(
            view: {
                TangemPayOnboardingCoordinatorView(coordinator: coordinator)
            },
            embedInNavigationStack: false,
            modalPresentationStyle: .overFullScreen
        )
    }

    private func constructNewsDetailsViewController(newsId: Int) -> UIViewController {
        var windowSize: CGSize?
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            windowSize = window.screen.bounds.size
        }

        return makeDeeplinkViewController(
            view: {
                NewsDeeplinkContainerView(newsId: newsId)
                    .environment(\.mainWindowSize, windowSize ?? .zero)
            },
            embedInNavigationStack: true
        )
    }
}

private extension CommonDeeplinkPresenter {
    private func expandMarketsBottomSheetIfPossible() {
        // If the markets bottom sheet is not currently shown,
        // it means we're not on the Main View and can't expand it.
        // Therefore, we discard the incoming action.
        guard mainBottomSheetUIManager.isShown else {
            incomingActionManager.discardIncomingAction()
            return
        }

        bottomSheetStateController.expand()
    }
}
