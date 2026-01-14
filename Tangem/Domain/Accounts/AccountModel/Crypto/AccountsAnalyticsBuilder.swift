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
    func setIsMainAccount(_ isMainAccount: Bool) -> Self
    @discardableResult
    func setDerivationIndex(_ index: Int) -> Self
    func build() -> [Analytics.ParameterKey: String]
}
