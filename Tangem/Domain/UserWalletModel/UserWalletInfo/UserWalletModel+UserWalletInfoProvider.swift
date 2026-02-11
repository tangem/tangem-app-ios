//
//  UserWalletModel+UserWalletInfoProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension UserWalletInfoProvider where Self: UserWalletModel {
    var userWalletInfo: UserWalletInfo {
        let emailDataProvider = EmailDataProviderTrampoline(
            _emailData: { [weak self] in
                self?.emailData ?? []
            },
            _emailConfig: { [weak self] in
                self?.emailConfig
            }
        )

        return UserWalletInfo(
            name: name,
            id: userWalletId,
            config: config,
            refcode: refcodeProvider?.getRefcode(),
            signer: signer,
            emailDataProvider: emailDataProvider
        )
    }
}

// MARK: - Auxiliary types

/// `UserWalletInfo` is a lightweight representation of `UserWalletModel` by design,
/// therefore this trampoline is used to prevent possible retain cycles and leaks.
private struct EmailDataProviderTrampoline: EmailDataProvider {
    var emailData: [EmailCollectedData] { _emailData() }
    let _emailData: () -> [EmailCollectedData]

    var emailConfig: EmailConfig? { _emailConfig() }
    let _emailConfig: () -> EmailConfig?
}
