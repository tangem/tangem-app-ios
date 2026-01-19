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
    private var isMainAccount: Bool?
    private var derivationIndex: Int?

    @discardableResult
    func setIsMainAccount(_ isMainAccount: Bool) -> Self {
        self.isMainAccount = isMainAccount
        return self
    }

    @discardableResult
    func setDerivationIndex(_ index: Int) -> Self {
        derivationIndex = index
        return self
    }

    func build() -> [Analytics.ParameterKey: String] {
        guard isMainAccount == false, let derivationIndex else {
            return [:]
        }

        return [.accountDerivation: "\(derivationIndex)"]
    }
}

/// Builder for single account analytics that includes main accounts.
/// Returns `[.accountDerivation: index]` for all accounts, including the main account.
final class SingleAccountAnalyticsBuilderIncludingMain: AccountsAnalyticsBuilder {
    private var derivationIndex: Int?

    @discardableResult
    func setIsMainAccount(_ isMainAccount: Bool) -> Self {
        // Ignored - this builder includes main accounts
        return self
    }

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
