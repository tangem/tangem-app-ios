//
//  TangemPayPaeraCustomerFlagRepository.swift
//  TangemPay
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public protocol TangemPayPaeraCustomerFlagRepository {
    func isPaeraCustomer(customerWalletId: String) -> Bool
    func setIsPaeraCustomer(for customerWalletId: String)
    func setIsKYCHidden(_ value: Bool, for customerWalletId: String)
}
