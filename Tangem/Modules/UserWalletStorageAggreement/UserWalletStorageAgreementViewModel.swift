//
//  UserWalletStorageAgreementViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI

final class UserWalletStorageAgreementViewModel: ObservableObject {
    // MARK: - ViewState

    // MARK: - Dependencies

    private unowned let coordinator: UserWalletStorageAgreementRoutable

    init(
        coordinator: UserWalletStorageAgreementRoutable
    ) {
        self.coordinator = coordinator
    }

    func accept() {
        coordinator.didAgree()
    }

    func decline() {
        coordinator.didDecline()
    }
}
