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

    @Published var referralViewModel: ReferralViewModel?

    required init(dismissAction: @escaping Action, popToRootAction: @escaping ParamsAction<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        referralViewModel = .init(coordinator: self,
                                  referralService: CommonReferralService(userWalletId: options.userWalletId),
                                  cardModel: options.cardModel)
    }
}

extension ReferralCoordinator {
    struct Options {
        let userWalletId: Data
        let cardModel: CardViewModel
    }
}

extension ReferralCoordinator: ReferralRoutable {
}
