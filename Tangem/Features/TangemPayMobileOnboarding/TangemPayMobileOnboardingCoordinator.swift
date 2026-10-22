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

    @Published private(set) var rootViewModel: TangemPayMobileOnboardingViewModel?
    @Published private(set) var tangemPayOnboardingCoordinator: TangemPayOnboardingCoordinator?

    @Published var webViewContainerViewModel: WebViewContainerViewModel?

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
    func openMain(userWalletModel: UserWalletModel) {
        dismiss(with: .main(userWalletModel: userWalletModel))
    }

    func openResidency(userWalletModel: UserWalletModel, interactor: any TangemPayResidencyInteractor) {
        let dismissAction: Action<TangemPayOnboardingCoordinator.DismissOptions?> = { [weak self] _ in
            self?.openMain(userWalletModel: userWalletModel)
        }

        let coordinator = TangemPayOnboardingCoordinator(dismissAction: dismissAction)
        coordinator.start(with: .init(residencyInteractor: interactor))
        tangemPayOnboardingCoordinator = coordinator
    }

    func openTermsFeesAndLimits() {
        webViewContainerViewModel = .init(
            url: AppConstants.tangemPayTermsAndLimitsURL,
            title: "",
            withCloseButton: true
        )
    }

    func openLegalDocument(url: URL) {
        webViewContainerViewModel = .init(
            url: url,
            title: "",
            withCloseButton: true
        )
    }
}

extension TangemPayMobileOnboardingCoordinator {
    enum OutputOptions {
        case main(userWalletModel: UserWalletModel)
    }
}
