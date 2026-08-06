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

extension TangemPayMobileOnboardingCoordinator {
    enum OutputOptions {
        case main(userWalletModel: UserWalletModel)
    }
}
