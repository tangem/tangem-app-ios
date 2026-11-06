//
//  AccountTypeAnalyticsBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

final class AccountTypeAnalyticsBuilder: AccountsAnalyticsBuilder {
    private var derivationIdentity: CryptoAccountDerivationIdentity?

    @discardableResult
    func setDerivationIdentity(_ identity: CryptoAccountDerivationIdentity) -> Self {
        derivationIdentity = identity
        return self
    }

    func build() -> [Analytics.ParameterKey: String] {
        guard let derivationIdentity else {
            return [:]
        }

        return [.accountType: derivationIdentity.type.analyticsValue.rawValue]
    }
}
