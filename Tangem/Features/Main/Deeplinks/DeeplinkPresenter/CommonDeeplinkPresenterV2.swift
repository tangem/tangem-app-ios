//
//  CommonDeeplinkPresenterV2.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets

final class CommonDeeplinkPresenterV2 {
    typealias DeepLinkDestination = MainCoordinator.DeepLinkDestination

    // MARK: - Properties

    @Injected(\.tangemPayAvailabilityRepository) private var tangemPayAvailabilityRepository: TangemPayAvailabilityRepository
    @Injected(\.overlayViewPresenter) private var overlayViewPresenter: OverlayViewPresenter
    @Injected(\.alertPresenter) private var alertPresenter: AlertPresenter

    private let coordinatorFactory: MainCoordinatorChildFactory

    // MARK: - Init

    init(coordinatorFactory: MainCoordinatorChildFactory) {
        self.coordinatorFactory = coordinatorFactory
    }
}

// MARK: - Deeplink Presenter

extension CommonDeeplinkPresenterV2: DeeplinkPresenter {
    @MainActor
    public func present(deepLink: DeepLinkDestination) {
        guard let view = constructViewForDeepLink(deepLink) else {
            return
        }

        let presentationView = OverlayView(
            id: deepLink.id,
            view: view,
            style: presentationStyle(deepLink),
            animated: animated(deepLink)
        )
        overlayViewPresenter.present(presentationView)
    }
}

// MARK: - Private Implementation

private extension CommonDeeplinkPresenterV2 {
    @ViewBuilder
    func makeDeeplinkView<Content: View>(
        @ViewBuilder view: () -> Content,
        embedInNavigationStack: Bool
    ) -> some View {
        let presenter = overlayViewPresenter
        if embedInNavigationStack {
            NavigationStack {
                view()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button(Localization.commonClose) {
                                Task { @MainActor in presenter.dismiss() }
                            }
                            .foregroundColor(Colors.Text.primary1)
                        }
                    }
            }
        } else {
            view()
        }
    }
}

private extension CommonDeeplinkPresenterV2 {
    private func constructViewForDeepLink(_ deepLink: DeepLinkDestination) -> AnyView? {
        switch deepLink {
        case .expressTransactionStatus(let walletModel, let userWalletModel, let pendingTransactionDetails):
            return constructTokenDetailsView(
                walletModel: walletModel,
                userWalletModel: userWalletModel,
                pendingTransactionDetails: pendingTransactionDetails
            )

        case .tokenDetails(let walletModel, let userWalletModel):
            return constructTokenDetailsView(
                walletModel: walletModel,
                userWalletModel: userWalletModel,
                pendingTransactionDetails: nil
            )

        case .buy(let userWalletModel):
            return constructBuyView(userWalletModel: userWalletModel)

        case .sell(let userWalletModel):
            return constructSellView(userWalletModel: userWalletModel)

        case .swap(let parameters):
            return constructSwapView(parameters: parameters)

        case .referral(let input):
            return constructReferralView(input: input)

        case .staking(let options):
            return constructStakingView(options: options)

        case .marketsTokenDetails(let tokenId):
            return constructMarketsTokenView(tokenId: tokenId)

        case .tokenExchanges(let tokenId):
            return constructMarketsExchangesListView(tokenId: tokenId)

        case .markets(let filter):
            return constructMarketsSearchView(filter: filter)

        case .onboardVisa(let deeplinkString):
            return constructTangemPayOnboardView(deeplinkString: deeplinkString)

        case .promo(let promoCode, let refcode, let campaign):
            return constructPromoView(promoCode: promoCode, refcode: refcode, campaign: campaign)

        case .newsDetails(let newsId):
            return constructNewsDetailsView(newsId: newsId)

        case .newsList(let initialCategoryId):
            return constructNewsListView(initialCategoryId: initialCategoryId)

        case .earn(let earnType, let networkId):
            return constructEarnView(earnType: earnType, networkId: networkId)

        case .externalLink, .tangemPayMain, .tangemPayTransactionDetails, .yield:
            return nil
        }
    }

    private func presentationStyle(_ deepLink: DeepLinkDestination) -> OverlayView.PresentationStyle {
        switch deepLink {
        case .promo, .onboardVisa:
            return .fullScreenCover

        case .expressTransactionStatus, .tokenDetails, .buy, .sell,
             .swap, .referral,
             .staking, .yield, .marketsTokenDetails, .tokenExchanges, .externalLink,
             .markets, .tangemPayMain, .tangemPayTransactionDetails, .newsDetails,
             .newsList, .earn:
            return .sheet
        }
    }

    /// Mirrors V1's `shouldAnimate` switch — `.promo` shows/dismisses without animation so the
    /// overFullScreen-style modal pops in instantly (the underlying view does its own fade).
    private func animated(_ deepLink: DeepLinkDestination) -> Bool {
        switch deepLink {
        case .promo:
            return false

        case .expressTransactionStatus, .tokenDetails, .buy, .sell,
             .swap, .referral,
             .staking, .yield, .marketsTokenDetails, .tokenExchanges, .externalLink,
             .markets, .onboardVisa, .tangemPayMain, .tangemPayTransactionDetails,
             .newsDetails, .newsList, .earn:
            return true
        }
    }
}

private extension CommonDeeplinkPresenterV2 {
    private func constructPromoView(promoCode: String, refcode: String?, campaign: String?) -> AnyView {
        let presenter = overlayViewPresenter
        return AnyView(
            PromocodeActivationView(
                promoCode: promoCode,
                refcode: refcode,
                campaign: campaign,
                dismissAction: { Task { @MainActor in presenter.dismiss() } }
            )
            .presentationBackground(.clear)
        )
    }

    private func constructTokenDetailsView(
        walletModel: any WalletModel,
        userWalletModel: UserWalletModel,
        pendingTransactionDetails: PendingTransactionDetails?
    ) -> AnyView? {
        let presenter = overlayViewPresenter
        let coordinator = coordinatorFactory.makeTokenDetailsCoordinator(dismissAction: { Task { @MainActor in presenter.dismiss() } })

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

        return AnyView(
            makeDeeplinkView(
                view: { TokenDetailsCoordinatorView(coordinator: coordinator) },
                embedInNavigationStack: true
            )
        )
    }

    private func constructReferralView(input: ReferralInputModel) -> AnyView {
        let presenter = overlayViewPresenter
        let coordinator = coordinatorFactory.makeReferralCoordinator(dismissAction: { Task { @MainActor in presenter.dismiss() } })

        coordinator.start(with: .init(input: input))
        return AnyView(
            makeDeeplinkView(
                view: { ReferralCoordinatorView(coordinator: coordinator) },
                embedInNavigationStack: true
            )
        )
    }

    private func constructBuyView(userWalletModel: UserWalletModel) -> AnyView? {
        if let backupAlert = UserWalletBackupStatusHelper().alert(for: userWalletModel.userWalletInfo) {
            alertPresenter.present(alert: backupAlert)
            return nil
        }

        let presenter = overlayViewPresenter
        let coordinator = coordinatorFactory.makeBuyCoordinator(dismissAction: { _ in Task { @MainActor in presenter.dismiss() } })

        coordinator.start(
            with: .init(
                userWalletModels: [userWalletModel],
                preferredWalletId: ActionButtonsBuyPreselection.userWalletId(for: userWalletModel)
            )
        )

        return AnyView(
            makeDeeplinkView(
                view: { ActionButtonsBuyCoordinatorView(coordinator: coordinator) },
                embedInNavigationStack: false
            )
        )
    }

    private func constructSellView(userWalletModel: UserWalletModel) -> AnyView {
        let presenter = overlayViewPresenter
        let coordinator = coordinatorFactory.makeSellCoordinator(
            userWalletModel: userWalletModel,
            dismissAction: { _ in Task { @MainActor in presenter.dismiss() } }
        )

        let tokenSelectorViewModel = TokenSelectorViewModel.common(availabilityProvider: .sell())
        coordinator.start(with: .init(tokenSelectorViewModel: tokenSelectorViewModel))
        return AnyView(
            makeDeeplinkView(
                view: { ActionButtonsSellCoordinatorView(coordinator: coordinator) },
                embedInNavigationStack: false
            )
        )
    }

    private func constructSwapView(parameters: PredefinedSwapParameters) -> AnyView? {
        let presenter = overlayViewPresenter
        let coordinator = SendCoordinator(
            dismissAction: { _ in Task { @MainActor in presenter.dismiss() } },
            popToRootAction: { _ in Task { @MainActor in presenter.dismiss() } }
        )
        coordinator.start(with: .init(type: .swap(parameters), source: .main))

        return AnyView(
            makeDeeplinkView(
                view: { SendCoordinatorView(coordinator: coordinator) },
                embedInNavigationStack: false
            )
        )
    }

    private func constructStakingView(options: StakingDetailsCoordinator.Options) -> AnyView {
        let presenter = overlayViewPresenter
        let coordinator = coordinatorFactory.makeStakingCoordinator(
            dismissAction: { Task { @MainActor in presenter.dismiss() } },
            popToRootAction: { _ in }
        )

        coordinator.start(with: options)
        return AnyView(
            makeDeeplinkView(
                view: { StakingDetailsCoordinatorView(coordinator: coordinator) },
                embedInNavigationStack: true
            )
        )
    }

    private func constructEarnView(earnType: EarnFilterType?, networkId: String?) -> AnyView {
        let presenter = overlayViewPresenter
        return AnyView(
            makeDeeplinkView(
                view: {
                    EarnDeeplinkContainerView(
                        earnType: earnType,
                        networkId: networkId,
                        dismissAction: { Task { @MainActor in presenter.dismiss() } }
                    )
                },
                embedInNavigationStack: false
            )
        )
    }

    private func constructMarketsTokenView(tokenId: String) -> AnyView {
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

        return AnyView(
            makeDeeplinkView(
                view: { MarketsTokenDetailsCoordinatorView(coordinator: coordinator) },
                embedInNavigationStack: true
            )
        )
    }

    private func constructTangemPayOnboardView(deeplinkString: String) -> AnyView? {
        guard let availableSelection = tangemPayAvailabilityRepository.tangemPayOfferAvailability.availableWalletSelection else {
            return nil
        }

        let presenter = overlayViewPresenter
        let coordinator = coordinatorFactory.makeTangemPayOnboardingCoordinator { _ in
            Task { @MainActor in presenter.dismiss() }
        }
        coordinator.start(with: .init(source: .deeplink(deeplinkString), availableSelection: availableSelection))

        return AnyView(
            makeDeeplinkView(
                view: {
                    TangemPayOnboardingCoordinatorView(coordinator: coordinator)
                },
                embedInNavigationStack: false
            )
        )
    }

    private func constructMarketsSearchView(filter: MarketsDeeplinkFilter) -> AnyView {
        let presenter = overlayViewPresenter
        let coordinator = coordinatorFactory.makeMarketsSearchCoordinator(dismissAction: { Task { @MainActor in presenter.dismiss() } })

        coordinator.start(
            with: .init(
                initialOrderType: filter.order,
                initialIntervalType: filter.interval,
                quotesRepositoryUpdateHelper: CommonMarketsQuotesUpdateHelper(),
                leadingButton: .close
            )
        )

        return AnyView(
            makeDeeplinkView(
                view: { MarketsSearchCoordinatorView(coordinator: coordinator) },
                embedInNavigationStack: true
            )
        )
    }

    private func constructMarketsExchangesListView(tokenId: String) -> AnyView {
        let viewModel = MarketsTokenDetailsExchangesListViewModel(
            tokenId: tokenId,
            numberOfExchangesListedOn: DeeplinkMarketsConstants.deeplinkExchangesSkeletonCount,
            presentationStyle: .navigationStack,
            exchangesListLoader: MarketsTokenDetailsDataProvider(),
            onBackButtonAction: {}
        )

        return AnyView(
            makeDeeplinkView(
                view: { MarketsTokenDetailsExchangesListView(viewModel: viewModel) },
                embedInNavigationStack: true
            )
        )
    }

    private func constructNewsDetailsView(newsId: Int) -> AnyView {
        let presenter = overlayViewPresenter
        return AnyView(
            makeDeeplinkView(
                view: { NewsDeeplinkContainerView(newsId: newsId, dismissAction: { Task { @MainActor in presenter.dismiss() } }) },
                embedInNavigationStack: true
            )
        )
    }

    private func constructNewsListView(initialCategoryId: Int?) -> AnyView {
        let presenter = overlayViewPresenter
        let coordinator = NewsListCoordinator(
            dismissAction: { Task { @MainActor in presenter.dismiss() } }
        )
        coordinator.start(with: .init(initialCategoryId: initialCategoryId, presentSource: .deeplink))

        return AnyView(
            makeDeeplinkView(
                view: { NewsListCoordinatorView(coordinator: coordinator) },
                embedInNavigationStack: true
            )
        )
    }
}

private enum DeeplinkMarketsConstants {
    /// Skeleton row count while exchanges load; deeplink has no prior `exchangesAmount` from token details API.
    static let deeplinkExchangesSkeletonCount = 5
}
