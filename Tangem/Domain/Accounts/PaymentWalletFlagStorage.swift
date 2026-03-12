//
//  PaymentWalletFlagStorage.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

/// Tracks whether the derived wallet at the payment derivation path (m/44'/60'/999999'/0/0)
/// was created already (TangemPay or VirtualAccount)
protocol PaymentWalletFlagStorage {
    func isPaymentWalletDerived(customerWalletId: String) -> Bool
    func setPaymentWalletDerived(_ value: Bool, for customerWalletId: String)
}
