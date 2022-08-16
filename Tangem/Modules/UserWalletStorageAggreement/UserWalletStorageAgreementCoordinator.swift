//
//  UserWalletStorageAgreementCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol UserWalletStorageAgreementCoordinatorRoutable: AnyObject {
    func didAgreeToSaveUserWallets()
    func didDeclineToSaveUserWallets()
}

class UserWalletStorageAgreementCoordinator: CoordinatorObject {
    let dismissAction: Action
    let popToRootAction: ParamsAction<PopToRootOptions>

    private let router: UserWalletStorageAgreementCoordinatorRoutable

    // MARK: - Root view model

    @Published private(set) var rootViewModel: UserWalletStorageAgreementViewModel?

    // MARK: - Child coordinators

    // MARK: - Child view models

    required init(
        dismissAction: @escaping Action,
        popToRootAction: @escaping ParamsAction<PopToRootOptions>,
        router: UserWalletStorageAgreementCoordinatorRoutable
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
        self.router = router
    }

    func start(with options: Options) {

    }

    func didAgree() {
        router.didAgreeToSaveUserWallets()
    }

    func didDecline() {
        router.didDeclineToSaveUserWallets()
    }
}

// MARK: - Options

extension UserWalletStorageAgreementCoordinator {
    enum Options {

    }
}

// MARK: - UserWalletStorageAgreementRoutable

extension UserWalletStorageAgreementCoordinator: UserWalletStorageAgreementRoutable {}
