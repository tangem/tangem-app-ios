//
//  TangemPayPaeraCustomerFlagRepository.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public protocol TangemPayPaeraCustomerFlagRepository {
    func isPaeraCustomer(customerWalletId: String) -> Bool
    func isKYCHidden(customerWalletId: String) -> Bool

    func setIsPaeraCustomer(_ value: Bool, for customerWalletId: String)
    func setIsKYCHidden(_ value: Bool, for customerWalletId: String)
    func setShouldShowGetBanner(_ value: Bool)
}
