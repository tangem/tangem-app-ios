//
//  TangemPayMobileOnboardingViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemMobileWalletSdk
import TangemPay
import struct TangemUIUtils.AlertBinder

protocol TangemPayMobileOnboardingRoutable: AnyObject {
    func openMain(userWalletModel: UserWalletModel)
    func openResidency(userWalletModel: UserWalletModel, interactor: any TangemPayResidencyInteractor)
    func openTermsFeesAndLimits()
    func openLegalDocument(url: URL)
}

final class TangemPayMobileOnboardingViewModel: ObservableObject {
    @Published var alert: AlertBinder?
    @Published var isCreating: Bool = false

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.pushNotificationsInteractor) private var pushNotificationsInteractor: PushNotificationsInteractor
    @Injected(\.tangemPayOnboardingAnalytics) private var analytics: TangemPayOnboardingAnalyticsService

    private let mobileWalletFeatureProvider = MobileWalletFeatureProvider()
    private let analyticsContextParams: Analytics.ContextParams = .custom(.mobileWallet)

    private weak var coordinator: TangemPayMobileOnboardingRoutable?

    init(coordinator: TangemPayMobileOnboardingRoutable) {
        self.coordinator = coordinator
    }

    func onAppear() {
        analytics.logBundleScreenOpened()
    }

    func getCard() {
        guard mobileWalletFeatureProvider.isAvailable else {
            alert = mobileWalletFeatureProvider.makeRestrictionAlert()
            return
        }

        if FeatureProvider.isAvailable(.mobileWalletMultiCreation),
           let restriction = MobileWalletLimitUtil().restriction(for: .create) {
            alert = restriction.makeAlert()
            return
        }

        guard !isCreating else { return }

        TangemPayMobileOnboardingService().markOnboardingShown()

        isCreating = true

        runTask(in: self) { viewModel in
            do {
                let creationUtil = MobileCreationUtil()
                let newUserWalletModel = try await creationUtil.makeCreatedModel()

                AmplitudeWrapper.shared.setUserIdIfOnboarding(userWalletId: newUserWalletModel.userWalletId)
                viewModel.logWalletCreatedAnalytics()

                try creationUtil.store(newUserWalletModel)

                await runOnMain { viewModel.pushNotificationsInteractor.suppressAfterLoginRequestsInCurrentSession() }

                let residencyInteractor = try await viewModel.acceptOffer(on: newUserWalletModel)

                await viewModel.didCreateWallet(newUserWalletModel, residencyInteractor: residencyInteractor)
            } catch {
                AppLogger.error("Failed to create wallet", error: error)
                await viewModel.didFailToCreateWallet()
            }
        }
    }

    func onTermsTap() {
        analytics.logTermsTapped()
        coordinator?.openTermsFeesAndLimits()
    }

    func openLegalDocument(url: URL) {
        coordinator?.openLegalDocument(url: url)
    }
}

@MainActor
private extension TangemPayMobileOnboardingViewModel {
    func didCreateWallet(_ userWalletModel: UserWalletModel, residencyInteractor: (any TangemPayResidencyInteractor)?) {
        isCreating = false

        guard let residencyInteractor else {
            coordinator?.openMain(userWalletModel: userWalletModel)
            return
        }

        coordinator?.openResidency(userWalletModel: userWalletModel, interactor: residencyInteractor)
    }

    func didFailToCreateWallet() {
        isCreating = false

        guard let userWalletModel = userWalletRepository.selectedModel else {
            return
        }

        coordinator?.openMain(userWalletModel: userWalletModel)
    }
}

private extension TangemPayMobileOnboardingViewModel {
    func acceptOffer(
        on userWalletModel: UserWalletModel
    ) async throws(TangemPayAuthorizationError) -> (any TangemPayResidencyInteractor)? {
        try await userWalletModel.accountModelsManager.authorizeTangemPayOfferForResidency(
            authorizingInteractor: userWalletModel.tangemPayAuthorizingInteractor
        )
    }

    func logWalletCreatedAnalytics() {
        var params: [Analytics.ParameterKey: String] = [
            .creationType: Analytics.ParameterValue.walletCreationTypeNewSeed.rawValue,
            .seedLength: "12",
            .passphrase: Analytics.ParameterValue.empty.rawValue,
            .source: MobileCreateWalletSource.createWalletIntro.analyticsParameterValue.rawValue,
        ]

        params.enrich(with: ReferralAnalyticsHelper().getReferralParams())

        Analytics.log(
            event: .walletCreatedSuccessfully,
            params: params,
            analyticsSystems: .all,
            contextParams: analyticsContextParams
        )
    }
}
