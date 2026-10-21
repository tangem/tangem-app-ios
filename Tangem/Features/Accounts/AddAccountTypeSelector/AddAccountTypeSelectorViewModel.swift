//
//  AddAccountTypeSelectorViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

final class AddAccountTypeSelectorViewModel: ObservableObject {
    private let userWalletConfig: UserWalletConfig?
    private weak var coordinator: AddAccountTypeSelectorRoutable?

    init(userWalletConfig: UserWalletConfig?, coordinator: AddAccountTypeSelectorRoutable?) {
        self.userWalletConfig = userWalletConfig
        self.coordinator = coordinator
    }

    func onCryptoAccountTap() {
        if let userWalletConfig {
            Analytics.log(event: .walletSettingsButtonAddAccount, params: [
                .productType: userWalletConfig.productType.rawValue,
                .source: Analytics.ParameterValue.settings.rawValue,
            ])
        }

        coordinator?.openCryptoAccountForm()
    }

    func onJointAccountTap() {
        coordinator?.openJointAccountManagement()
    }
}
