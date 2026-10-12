//
//  AccountsAnalyticsBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

// MARK: - AccountModelAnalyticsProviding

protocol AccountModelAnalyticsProviding {
    func analyticsParameters(with builder: AccountsAnalyticsBuilder) -> [Analytics.ParameterKey: String]
}

// MARK: - AccountsAnalyticsBuilder

protocol AccountsAnalyticsBuilder {
    @discardableResult
    func setDerivationIdentity(_ identity: CryptoAccountDerivationIdentity) -> Self
    func build() -> [Analytics.ParameterKey: String]
}
