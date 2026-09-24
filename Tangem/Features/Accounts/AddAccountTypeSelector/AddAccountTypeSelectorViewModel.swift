//
//  AddAccountTypeSelectorViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import protocol TangemUI.FloatingSheetContentViewModel

final class AddAccountTypeSelectorViewModel: ObservableObject {
    private let accountModelsManager: any AccountModelsManager
    private let userWalletConfig: UserWalletConfig
    private let shouldLogAddAccountTap: Bool
    private weak var coordinator: AddAccountTypeSelectorRoutable?

    init(
        accountModelsManager: any AccountModelsManager,
        userWalletConfig: UserWalletConfig,
        coordinator: AddAccountTypeSelectorRoutable?,
        shouldLogAddAccountTap: Bool = true
    ) {
        self.accountModelsManager = accountModelsManager
        self.userWalletConfig = userWalletConfig
        self.shouldLogAddAccountTap = shouldLogAddAccountTap
        self.coordinator = coordinator
    }

    func onCryptoAccountTap() {
        if shouldLogAddAccountTap {
            Analytics.log(event: .walletSettingsButtonAddAccount, params: [
                .productType: userWalletConfig.productType.rawValue,
                .source: Analytics.ParameterValue.settings.rawValue,
            ])
        }

        coordinator?.openCryptoAccountForm(
            accountModelsManager: accountModelsManager,
            userWalletConfig: userWalletConfig
        )
    }

    func onJointAccountTap() {
        coordinator?.openJointAccountManagement(
            accountModelsManager: accountModelsManager,
            userWalletConfig: userWalletConfig
        )
    }

    func onCloseTap() {
        coordinator?.dismissAddAccountTypeSelector()
    }
}

// MARK: - FloatingSheetContentViewModel

extension AddAccountTypeSelectorViewModel: FloatingSheetContentViewModel {}
