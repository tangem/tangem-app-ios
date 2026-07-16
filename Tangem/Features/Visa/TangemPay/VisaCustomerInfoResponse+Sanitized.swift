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
            productInstances: productInstances,
            paymentAccount: paymentAccount,
            kyc: nil,
            card: card?.sanitizedForDiskCache(),
            cards: cards.map { $0.sanitizedForDiskCache() },
            depositAddress: depositAddress
        )
    }
}

private extension VisaCustomerInfoResponse.Card {
    func sanitizedForDiskCache() -> VisaCustomerInfoResponse.Card {
        VisaCustomerInfoResponse.Card(
            id: id,
            cardNumberEnd: cardNumberEnd,
            expirationMonth: "",
            expirationYear: "",
            token: "",
            embossName: "",
            cardType: cardType,
            cardStatus: cardStatus,
            // The legacy single-card flow drops `isPinSet` from the disk cache; the multi-card flow keeps it.
            isPinSet: FeatureProvider.isAvailable(.tangemPayMultipleCards) ? isPinSet : false
        )
    }
}
