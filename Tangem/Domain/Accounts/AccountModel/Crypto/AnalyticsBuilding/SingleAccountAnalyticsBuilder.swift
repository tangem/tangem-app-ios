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
    private var derivationIndex: Int?

    @discardableResult
    func setDerivationIndex(_ index: Int) -> Self {
        derivationIndex = index
        return self
    }

    func build() -> [Analytics.ParameterKey: String] {
        guard let derivationIndex else {
            return [:]
        }

        return [.accountDerivation: "\(derivationIndex)"]
    }
}
