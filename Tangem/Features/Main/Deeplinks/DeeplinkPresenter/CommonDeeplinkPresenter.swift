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

    @Injected(\.tangemPayAvailabilityRepository) private var tangemPayAvailabilityRepository: TangemPayAvailabilityRepository
    @Injected(\.alertPresenter) private var alertPresenter: AlertPresenter

    private let coordinatorFactory: MainCoordinatorChildFactory

    // MARK: - Init

    init(coordinatorFactory: MainCoordinatorChildFactory) {
        self.coordinatorFactory = coordinatorFactory
    }
}

// MARK: - Deeplink Presenter

extension CommonDeeplinkPresenter: DeeplinkPresenter {
    @MainActor
    public func present(deepLink: DeepLinkDestination) {
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

        case .swap(let parameters):
            return constructSwapViewController(parameters: parameters)

        case .referral(let input):
            return constructReferralViewController(input: input)

        case .staking(let options):
            return constructStakingViewController(options: options)

        case .marketsTokenDetails(let tokenId):
            return constructMarketsTokenViewController(tokenId: tokenId)

        case .tokenExchanges(let tokenId):
            return constructMarketsExchangesListViewController(tokenId: tokenId)

        case .markets(let filter):
            return constructMarketsSearchViewController(filter: filter)

        case .onboardVisa(let deeplinkString):
            return constructTangemPayOnboardViewController(
                deeplinkString: deeplinkString,
            )

        case .promo(let promoCode, let refcode, let campaign):
            return constructPromoViewController(promoCode: promoCode, refcode: refcode, campaign: campaign)

        case .newsDetails(let newsId):
            return constructNewsDetailsViewController(newsId: newsId)

        case .newsList(let initialCategoryId):
            return constructNewsListViewController(initialCategoryId: initialCategoryId)

        case .earn(let earnType, let networkId):
            return constructEarnViewController(earnType: earnType, networkId: networkId)

        case .externalLink, .tangemPayMain, .tangemPayTransactionDetails, .yield:
            return nil
        }
    }
}

private extension CommonDeeplinkPresenter {
    private func constructPromoViewController(promoCode: String, refcode: String?, campaign: String?) -> UIViewController {
        let viewController = makeDeeplinkViewController(
            view: {
                PromocodeActivationView(
                    promoCode: promoCode,
                    refcode: refcode,
                    campaign: campaign,
                    dismissAction: { UIApplication.dismissTop(animated: false) }
                )
            },
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

    private func constructBuyViewController(userWalletModel: UserWalletModel) -> UIViewController? {
        if let backupAlert = UserWalletBackupStatusHelper().alert(for: userWalletModel.userWalletInfo) {
            alertPresenter.present(alert: backupAlert)
            return nil
        }

        let coordinator = coordinatorFactory.makeBuyCoordinator(dismissAction: { _ in UIApplication.dismissTop() })

        coordinator.start(
            with: .init(userWalletModels: [userWalletModel])
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

        let tokenSelectorViewModel = TokenSelectorViewModel.common(
            walletsProvider: .standardAccountsOnly(),
            availabilityProvider: .sell()
        )
        coordinator.start(with: .init(tokenSelectorViewModel: tokenSelectorViewModel))
        return makeDeeplinkViewController(
            view: { ActionButtonsSellCoordinatorView(coordinator: coordinator) },
            embedInNavigationStack: false
        )
    }

    private func constructSwapViewController(parameters: PredefinedSwapParameters) -> UIViewController? {
        let coordinator = SendCoordinator(
            dismissAction: { _ in UIApplication.dismissTop() },
            popToRootAction: { _ in UIApplication.dismissTop() }
        )
        coordinator.start(with: .init(type: .swap(parameters), source: .main))

        return makeDeeplinkViewController(
            view: { SendCoordinatorView(coordinator: coordinator) },
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

    private func constructEarnViewController(earnType: EarnFilterType?, networkId: String?) -> UIViewController {
        return makeDeeplinkViewController(
            view: {
                EarnDeeplinkContainerView(
                    earnType: earnType,
                    networkId: networkId,
                    dismissAction: { UIApplication.dismissTop() }
                )
            },
            embedInNavigationStack: false
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
            stakingOpportunities: nil,
            networks: nil,
        )

        let coordinator = coordinatorFactory.makeMarketsTokenDetailsCoordinator()
        coordinator.start(with: .init(info: tokenModel, style: .navigationStack))

        let windowSize = makeFirstWindowSceneSize()

        return makeDeeplinkViewController(
            view: {
                MarketsTokenDetailsCoordinatorView(coordinator: coordinator)
                    .environment(\.mainWindowSize, windowSize)
            },
            embedInNavigationStack: true
        )
    }

    private func constructTangemPayOnboardViewController(deeplinkString: String) -> UIViewController? {
        guard let availableSelection = tangemPayAvailabilityRepository.tangemPayOfferAvailability.availableWalletSelection else {
            return nil
        }

        let coordinator = coordinatorFactory.makeTangemPayOnboardingCoordinator { _ in
            UIApplication.dismissTop()
        }
        coordinator.start(with: .init(source: .deeplink(deeplinkString), availableSelection: availableSelection))

        return makeDeeplinkViewController(
            view: {
                TangemPayOnboardingCoordinatorView(coordinator: coordinator)
            },
            embedInNavigationStack: false,
            modalPresentationStyle: .overFullScreen
        )
    }

    private func constructMarketsSearchViewController(filter: MarketsDeeplinkFilter) -> UIViewController {
        let coordinator = coordinatorFactory.makeMarketsSearchCoordinator(dismissAction: { UIApplication.dismissTop() })

        coordinator.start(
            with: .init(
                initialOrderType: filter.order,
                initialIntervalType: filter.interval,
                quotesRepositoryUpdateHelper: CommonMarketsQuotesUpdateHelper(),
                leadingButton: .close
            )
        )

        let windowSize = makeFirstWindowSceneSize()

        return makeDeeplinkViewController(
            view: {
                MarketsSearchCoordinatorView(coordinator: coordinator)
                    .environment(\.mainWindowSize, windowSize)
            },
            embedInNavigationStack: true
        )
    }

    private func constructMarketsExchangesListViewController(tokenId: String) -> UIViewController {
        let viewModel = MarketsTokenDetailsExchangesListViewModel(
            tokenId: tokenId,
            numberOfExchangesListedOn: DeeplinkMarketsConstants.deeplinkExchangesSkeletonCount,
            presentationStyle: .navigationStack,
            exchangesListLoader: MarketsTokenDetailsDataProvider(),
            onBackButtonAction: {}
        )

        return makeDeeplinkViewController(
            view: { MarketsTokenDetailsExchangesListView(viewModel: viewModel) },
            embedInNavigationStack: true
        )
    }

    private func constructNewsDetailsViewController(newsId: Int) -> UIViewController {
        let windowSize = makeFirstWindowSceneSize()

        return makeDeeplinkViewController(
            view: {
                NewsDeeplinkContainerView(newsId: newsId, dismissAction: { UIApplication.dismissTop() })
                    .environment(\.mainWindowSize, windowSize)
            },
            embedInNavigationStack: true
        )
    }

    private func constructNewsListViewController(initialCategoryId: Int?) -> UIViewController {
        let windowSize = makeFirstWindowSceneSize()

        let coordinator = NewsListCoordinator(
            dismissAction: { UIApplication.dismissTop() }
        )
        coordinator.start(with: .init(initialCategoryId: initialCategoryId, presentSource: .deeplink))

        return makeDeeplinkViewController(
            view: {
                NewsListCoordinatorView(coordinator: coordinator)
                    .environment(\.mainWindowSize, windowSize)
            },
            embedInNavigationStack: true
        )
    }

    /// When opening MarketsTokenDetailsView via deeplink (using UIKit via AppPresenter.show method),
    /// the new SwiftUI view hierarchy doesn't inherit the original Environment values.
    /// Since some views inside MarketsTokenDetailsCoordinatorView rely on environment value `.mainWindowSize`
    /// for layout calculations, we manually inject the current window size here.
    private func makeFirstWindowSceneSize() -> CGSize {
        var windowSize: CGSize?
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            windowSize = window.screen.bounds.size
        }

        return windowSize ?? .zero
    }
}

private enum DeeplinkMarketsConstants {
    /// Skeleton row count while exchanges load; deeplink has no prior `exchangesAmount` from token details API.
    static let deeplinkExchangesSkeletonCount = 5
}
