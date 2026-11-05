//
//  TangemPayUnifiedOnboarding.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

enum TangemPayUnifiedOnboarding {
    static var isEnabled: Bool {
        FeatureProvider.isAvailable(.tangemPayMoneyAccount) && FeatureProvider.isAvailable(.tangemPayCustomerSummary)
    }
}
