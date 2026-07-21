//
//  TangemPayAccountBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemPay

protocol TangemPayAccountBuilder {
    func makeTangemPayAccount(
        customerInfo: VisaCustomerInfoResponse,
        account: (any TangemPayAccountModel)?
    ) -> TangemPayAccount
}
