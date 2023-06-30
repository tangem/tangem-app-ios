//
//  ReferralCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

class ReferralCoordinator: CoordinatorObject {
    var dismissAction: Action
    var popToRootAction: ParamsAction<PopToRootOptions>

    @Published var referralViewModel: ReferralViewModel? = nil
    @Published var tosViewModel: WebViewContainerViewModel? = nil

    required init(dismissAction: @escaping Action, popToRootAction: @escaping ParamsAction<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        referralViewModel = .init(
            userWalletId: options.userWalletId,
            userTokensManager: options.userTokensManager,
            walletModelsManager: options.walletModelsManager,
            coordinator: self
        )
    }
}

extension ReferralCoordinator {
    struct Options {
        let userWalletId: Data
        let userTokensManager: UserTokensManager
        let walletModelsManager: WalletModelsManager
    }
}

extension ReferralCoordinator: ReferralRoutable {
    func openTOS(with url: URL) {
        tosViewModel = WebViewContainerViewModel(
            url: url,
            title: Localization.detailsReferralTitle
        )
    }
}
