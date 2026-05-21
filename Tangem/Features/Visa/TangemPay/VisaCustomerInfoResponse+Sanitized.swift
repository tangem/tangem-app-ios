//
//  VisaCustomerInfoResponse+Sanitized.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemPay

extension VisaCustomerInfoResponse {
    func sanitizedForDiskCache() -> VisaCustomerInfoResponse {
        VisaCustomerInfoResponse(
            id: id,
            state: state,
            createdAt: createdAt,
            productInstance: productInstance,
            paymentAccount: paymentAccount,
            kyc: nil,
            card: card?.sanitizedForDiskCache(),
            depositAddress: depositAddress
        )
    }
}

private extension VisaCustomerInfoResponse.Card {
    func sanitizedForDiskCache() -> VisaCustomerInfoResponse.Card {
        VisaCustomerInfoResponse.Card(
            cardNumberEnd: cardNumberEnd,
            expirationMonth: "",
            expirationYear: "",
            token: "",
            embossName: "",
            cardType: cardType,
            cardStatus: cardStatus,
            isPinSet: false
        )
    }
}
