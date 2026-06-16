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
import struct TangemUIUtils.AlertBinder

protocol TangemPayMobileOnboardingRoutable: AnyObject {
    func openActivateWallet(userWalletModel: UserWalletModel)
    func openTermsFeesAndLimits()
    func openTos()
}

final class TangemPayMobileOnboardingViewModel: ObservableObject {
    @Published var alert: AlertBinder?
    @Published var isCreating: Bool = false

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    private let mobileWalletFeatureProvider = MobileWalletFeatureProvider()
    private let analyticsContextParams: Analytics.ContextParams = .custom(.mobileWallet)

    private weak var coordinator: TangemPayMobileOnboardingRoutable?

    init(coordinator: TangemPayMobileOnboardingRoutable) {
        self.coordinator = coordinator
    }

    func onAppear() {
        Analytics.log(.visaOnboardingVisaShortForHWActivationScreenOpened, contextParams: analyticsContextParams)
    }

    func getCard() {
        guard mobileWalletFeatureProvider.isAvailable else {
            alert = mobileWalletFeatureProvider.makeRestrictionAlert()
            return
        }
        guard !isCreating else { return }

        TangemPayMobileOnboardingService().markOnboardingShown()

        isCreating = true

        runTask(in: self) { viewModel in
            do {
                let initializer = MobileWalletInitializer()
                let walletInfo = try await initializer.initializeWallet(mnemonic: nil, passphrase: nil)

                Task.detached {
                    let userWalletConfig = MobileUserWalletConfig(mobileWalletInfo: walletInfo)
                    if let userWalletId = UserWalletId(config: userWalletConfig) {
                        let walletCreationHelper = WalletCreationHelper(
                            userWalletId: userWalletId,
                            userWalletName: nil,
                            userWalletConfig: userWalletConfig
                        )
                        try? await walletCreationHelper.createWallet()
                    }
                }

                guard let newUserWalletModel = CommonUserWalletModelFactory().makeModel(
                    walletInfo: .mobileWallet(walletInfo),
                    keys: .mobileWallet(keys: walletInfo.keys),
                ) else {
                    throw UserWalletRepositoryError.cantUnlockWallet
                }

                AmplitudeWrapper.shared.setUserIdIfOnboarding(userWalletId: newUserWalletModel.userWalletId)
                viewModel.logWalletCreatedAnalytics()

                try viewModel.userWalletRepository.add(userWalletModel: newUserWalletModel)

                await viewModel.didCreateWallet(userWalletModel: newUserWalletModel)
            } catch {
                AppLogger.error("Failed to create wallet", error: error)
                await viewModel.didFailToCreateWallet()
            }
        }
    }

    func onTermsTap() {
        coordinator?.openTermsFeesAndLimits()
    }

    func onTosTap() {
        coordinator?.openTos()
    }
}

@MainActor
private extension TangemPayMobileOnboardingViewModel {
    func didCreateWallet(userWalletModel: UserWalletModel) {
        isCreating = false
        coordinator?.openActivateWallet(userWalletModel: userWalletModel)
    }

    func didFailToCreateWallet() {
        isCreating = false
    }
}

private extension TangemPayMobileOnboardingViewModel {
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
