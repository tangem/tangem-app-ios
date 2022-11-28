//
//  UserWalletStorageAgreementViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI

final class UserWalletStorageAgreementViewModel: ObservableObject, Identifiable {
    // MARK: - ViewState

    let isStandalone: Bool

    // MARK: - Dependencies

    private unowned let coordinator: UserWalletStorageAgreementRoutable?

    init(
        isStandalone: Bool,
        coordinator: UserWalletStorageAgreementRoutable?
    ) {
        self.isStandalone = isStandalone
        self.coordinator = coordinator
    }

    func accept() {
        coordinator?.didAgreeToSaveUserWallets()
    }

    func decline() {
        coordinator?.didDeclineToSaveUserWallets()
    }
}
