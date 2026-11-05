//
//  TangemPayUnifiedOnboardingInteractor.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemPay

protocol TangemPayUnifiedOnboardingInteractor: TangemPayTariffPlanSelector {
    func loadProductsAvailability() async throws -> TangemPayProductsAvailability
    func placeOnboardingOrder(
        products: TangemPayProductsAvailability,
        plan: TangemPayTariffPlanTransition?,
        addressSigner: TangemPayBankingAccountAddressSigning
    ) async throws(TangemPayOnboardingOrderError)
    func hideAccountFromHome()
}

enum TangemPayOnboardingOrderError: Error {
    case cancelled
    case notEligible
    case alreadyOnboarded
    case failed(Error)
}
