//
//  SingleAccountAnalyticsBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

/// Builder for single account analytics.
/// Returns `[.accountDerivation: index]` for non-main accounts.
/// Main accounts are skipped and return an empty dictionary.
final class SingleAccountAnalyticsBuilder: AccountsAnalyticsBuilder {
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

        // The parameter has always been numeric, and both kinds of account report the bare index they are numbered by
        return [.accountDerivation: "\(derivationIdentity.derivationIndex)"]
    }
}
