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
        referralViewModel = .init(cardModel: options.cardModel,
                                  userWalletId: options.userWalletId,
                                  coordinator: self)
    }
}

extension ReferralCoordinator {
    struct Options {
        let cardModel: CardViewModel
        let userWalletId: Data
    }
}

extension ReferralCoordinator: ReferralRoutable {
    func openTOS(with url: URL) {
        tosViewModel = WebViewContainerViewModel(url: url,
                                                 title: L10n.detailsReferralTitle)
    }
}
