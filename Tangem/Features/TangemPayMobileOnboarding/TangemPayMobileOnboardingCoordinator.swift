//
//  TangemPayMobileOnboardingCoordinator.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import SwiftUI

class TangemPayMobileOnboardingCoordinator: CoordinatorObject {
    let dismissAction: Action<OutputOptions>
    let popToRootAction: Action<PopToRootOptions>

    @Injected(\.tangemPayAvailabilityRepository) private var tangemPayAvailabilityRepository: TangemPayAvailabilityRepository

    @Published private(set) var rootViewModel: TangemPayMobileOnboardingViewModel?
    @Published private(set) var isProcessing: Bool = false

    @Published private(set) var onboardingCoordinator: OnboardingCoordinator?
    @Published var webViewContainerViewModel: WebViewContainerViewModel?

    private var activatedUserWalletModel: UserWalletModel?

    required init(
        dismissAction: @escaping Action<OutputOptions>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Void = ()) {
        rootViewModel = TangemPayMobileOnboardingViewModel(coordinator: self)
    }
}

extension TangemPayMobileOnboardingCoordinator: TangemPayMobileOnboardingRoutable {
    func openActivateWallet(userWalletModel: UserWalletModel) {
        activatedUserWalletModel = userWalletModel

        let input = MobileOnboardingInput(flow: .tangemPayActivate(userWalletModel: userWalletModel, source: .main(action: .backup)))

        openOnboarding(options: .mobileInput(input))
    }

    func openTermsFeesAndLimits() {
        webViewContainerViewModel = .init(
            url: AppConstants.tangemPayTermsAndLimitsURL,
            title: "",
            withCloseButton: true
        )
    }

    func openTos() {
        webViewContainerViewModel = .init(
            url: AppConstants.tosURL,
            title: "",
            withCloseButton: true
        )
    }
}

private extension TangemPayMobileOnboardingCoordinator {
    func openOnboarding(options: OnboardingCoordinator.Options) {
        let dismissAction: Action<OnboardingCoordinator.OutputOptions> = { [weak self] outcome in
            Task { @MainActor [weak self] in
                guard let self else { return }

                switch outcome {
                case .main(let userWalletModel):
                    await routeAfterOnboarding(userWalletModel: userWalletModel)
                case .dismiss:
                    if let userWalletModel = activatedUserWalletModel {
                        await routeAfterOnboarding(userWalletModel: userWalletModel)
                    } else {
                        onboardingCoordinator = nil
                    }
                }
            }
        }

        let coordinator = OnboardingCoordinator(dismissAction: dismissAction)
        coordinator.start(with: options)
        onboardingCoordinator = coordinator
    }

    @MainActor
    func routeAfterOnboarding(userWalletModel: UserWalletModel) async {
        let isBackupCompleted = !userWalletModel.config.hasFeature(.mnemonicBackup)
        let isAccessCodeSet = userWalletModel.config.userWalletAccessCodeStatus.hasAccessCode

        guard isBackupCompleted, isAccessCodeSet else {
            dismiss(with: .main(userWalletModel: userWalletModel))
            return
        }

        isProcessing = true

        await userWalletModel.accountModelsManager.acceptTangemPayOffer(
            authorizingInteractor: userWalletModel.tangemPayAuthorizingInteractor
        )

        isProcessing = false
        onboardingCoordinator = nil
        dismiss(with: .main(userWalletModel: userWalletModel))
    }

    func isUserEligibleForTangemPay(customerWalletId: String) async -> Bool {
        _ = await tangemPayAvailabilityRepository.requestEligibleDistributionChannels()

        let values = await tangemPayAvailabilityRepository
            .tangemPayDetailsEntrypointEligibleWalletSelectionPublisher
            .values

        for await selection in values {
            return selection?.userWalletModelsIds.contains(customerWalletId) == true
        }

        return false
    }
}

extension TangemPayMobileOnboardingCoordinator {
    enum OutputOptions {
        case main(userWalletModel: UserWalletModel)
    }
}
