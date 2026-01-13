//
//  VisaCustomerCardInfo.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemPay

public struct VisaCustomerCardInfo {
    public let paymentAccount: String
    public let cardWalletAddress: String
    public let customerInfo: TangemPayCustomer?
}

public enum VisaPaymentAccountAddressProviderError: LocalizedError {
    case bffIsNotAvailable
    case missingProductInstanceForCardId
    case missingPaymentAccountForCard
}
