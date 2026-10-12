//
//  PairedAccountAnalyticsBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

/// Builder for paired account analytics (source/destination scenarios).
/// Returns `[.accountDerivationFrom: index]` for source or `[.accountDerivationTo: index]` for destination.
/// Main accounts are skipped and return an empty dictionary.
final class PairedAccountAnalyticsBuilder: AccountsAnalyticsBuilder {
    private let role: Role
    private var derivationIdentity: CryptoAccountDerivationIdentity?

    init(role: Role) {
        self.role = role
    }

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
        return [role.analyticsKey: "\(derivationIdentity.derivationIndex)"]
    }
}

extension PairedAccountAnalyticsBuilder {
    enum Role {
        case source
        case destination

        var analyticsKey: Analytics.ParameterKey {
            switch self {
            case .source: .accountDerivationFrom
            case .destination: .accountDerivationTo
            }
        }
    }
}
