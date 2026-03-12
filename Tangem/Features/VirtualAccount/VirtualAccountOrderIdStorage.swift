//
//  VirtualAccountOrderIdStorage.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol VirtualAccountOrderIdStorage {
    func vaOnboardingOrderId(customerWalletId: String) -> String?
    func vaOnboardingWalletId(customerWalletId: String) -> String?
    func saveVAOnboarding(orderId: String, walletId: String, customerWalletId: String)
    func deleteVAOnboarding(customerWalletId: String)
}
