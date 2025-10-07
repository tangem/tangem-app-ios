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
    func makeDeeplinkViewController<Content: View>(@ViewBuilder view: () -> Content, embedInNavigationView: Bool) -> UIViewController {
        if embedInNavigationView {
            let navRoot = NavigationView {
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
            return UIHostingController(rootView: navRoot)
        } else {
            return UIHostingController(rootView: view())
        }
    }
}

private extension CommonDeeplinkPresenter {
    private func constructViewControllerForDeepLink(_ deepLink: DeepLinkDestination) -> UIViewController? {
        switch deepLink {
        case .expressTransactionStatus(let walletModel, let userWalletModel, let pendingTransactionDetails):
            return constructTokenDetailsViewControllerWithPendingTransaction(
                walletModel: walletModel,
                userWalletModel: userWalletModel,
                pendingTransactionDetails: pendingTransactionDetails
            )

        case .tokenDetails(let walletModel, let userWalletModel):
            return constructTokenDetailsViewController(walletModel: walletModel, userWalletModel: userWalletModel)

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

        case .onboardVisa(let deeplinkString, let userWalletModel):
            return constructTangemPayOnboardViewController(
                deeplinkString: deeplinkString,
                userWalletModel: userWalletModel
            )

        case .promo(let promoCode):
            return constructPromoViewController(promoCode: promoCode)

        case .externalLink, .market:
            return nil
        }
    }
}

private extension CommonDeeplinkPresenter {
    private func constructPromoViewController(promoCode: String) -> UIViewController {
        let viewController = makeDeeplinkViewController(view: { PromocodeActivationView(promoCode: promoCode) }, embedInNavigationView: false)

        viewController.view.backgroundColor = .clear
        viewController.modalPresentationStyle = .overFullScreen

        return viewController
    }

    private func constructTokenDetailsViewControllerWithPendingTransaction(
        walletModel: any WalletModel,
        userWalletModel: UserWalletModel,
        pendingTransactionDetails: PendingTransactionDetails
    ) -> UIViewController {
        let coordinator = coordinatorFactory.makeTokenDetailsCoordinator(dismissAction: { UIApplication.dismissTop() })

        coordinator.start(
            with: .init(
                userWalletModel: userWalletModel,
                walletModel: walletModel,
                pendingTransactionDetails: pendingTransactionDetails
            )
        )

        return makeDeeplinkViewController(
            view: { TokenDetailsCoordinatorView(coordinator: coordinator) },
            embedInNavigationView: true
        )
    }

    private func constructTokenDetailsViewController(walletModel: any WalletModel, userWalletModel: UserWalletModel) -> UIViewController {
        let coordinator = coordinatorFactory.makeTokenDetailsCoordinator(dismissAction: { UIApplication.dismissTop() })

        coordinator.start(
            with: .init(
                userWalletModel: userWalletModel,
                walletModel: walletModel,
                pendingTransactionDetails: nil
            )
        )

        return makeDeeplinkViewController(
            view: { TokenDetailsCoordinatorView(coordinator: coordinator) },
            embedInNavigationView: true
        )
    }

    private func constructReferralViewController(input: ReferralInputModel) -> UIViewController {
        let coordinator = coordinatorFactory.makeReferralCoordinator(dismissAction: { UIApplication.dismissTop() })

        coordinator.start(with: .init(input: input))
        return makeDeeplinkViewController(
            view: { ReferralCoordinatorView(coordinator: coordinator) },
            embedInNavigationView: true
        )
    }

    private func constructBuyViewController(userWalletModel: UserWalletModel) -> UIViewController {
        let coordinator = coordinatorFactory.makeBuyCoordinator(dismissAction: { UIApplication.dismissTop() })

        coordinator.start(
            with: .default(
                options: .init(
                    userWalletModel: userWalletModel,
                    expressTokensListAdapter: CommonExpressTokensListAdapter(userWalletModel: userWalletModel),
                    tokenSorter: CommonBuyTokenAvailabilitySorter(userWalletModelConfig: userWalletModel.config)
                )
            )
        )

        return makeDeeplinkViewController(
            view: { ActionButtonsBuyCoordinatorView(coordinator: coordinator) },
            embedInNavigationView: false
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
            embedInNavigationView: false
        )
    }

    private func constructSwapViewController(userWalletModel: UserWalletModel) -> UIViewController {
        let coordinator = coordinatorFactory.makeSwapCoordinator(
            userWalletModel: userWalletModel,
            dismissAction: { UIApplication.dismissTop() }
        )

        coordinator.start(with: .default)
        return makeDeeplinkViewController(
            view: { ActionButtonsSwapCoordinatorView(coordinator: coordinator) },
            embedInNavigationView: false
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
            embedInNavigationView: true
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
            embedInNavigationView: true
        )
    }

    private func constructTangemPayOnboardViewController(
        deeplinkString: String,
        userWalletModel: UserWalletModel
    ) -> UIViewController {
        var viewController: UIViewController?

        let viewModel = TangemPayOnboardingViewModel(
            deeplinkString: deeplinkString,
            userWalletModel: userWalletModel,
            closeOfferScreen: { @MainActor in
                viewController?.dismiss(animated: true)
            }
        )

        let view = TangemPayOnboardingView(viewModel: viewModel)
        let controller = UIHostingController(rootView: view)
        controller.modalPresentationStyle = .overFullScreen

        viewController = controller

        return controller
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
