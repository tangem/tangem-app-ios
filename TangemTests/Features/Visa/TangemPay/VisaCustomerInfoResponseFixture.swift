//
//  VisaCustomerInfoResponseFixture.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemPay

enum VisaCustomerInfoResponseFixture {
    static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    static func fullyPopulated(
        cardToken: String = "default-card-token",
        cardEmbossName: String = "DEFAULT EMBOSS NAME",
        cardExpirationMonth: String = "12",
        cardExpirationYear: String = "2030",
        cardIsPinSet: Bool = true
    ) throws -> VisaCustomerInfoResponse {
        let json: [String: Any] = [
            "id": "customer-id-123",
            "state": "ACTIVE",
            "createdAt": "2026-01-01T00:00:00Z",
            "productInstance": [
                "id": "product-instance-id",
                "cardWalletAddress": "0xCARDWALLET",
                "cardId": "card-id-1",
                "cid": "cid-1",
                "status": "ACTIVE",
                "updatedAt": "2026-02-01T00:00:00Z",
                "paymentAccountId": "payment-account-id",
                "displayName": "My Card",
                "adminCardLimit": ["amount": 100_000, "periodType": "MONTHLY"],
                "actualCardLimit": ["amount": 50_000, "periodType": "MONTHLY"],
            ],
            "paymentAccount": [
                "id": "payment-account-id",
                "customerWalletAddress": "0xCUSTOMERWALLET",
                "address": "0xPAYMENTACCOUNT",
            ],
            "kyc": [
                "id": "kyc-id",
                "provider": "sumsub",
                "status": "APPROVED",
                "risk": "LOW",
                "reviewAnswer": "GREEN",
                "createdAt": "2025-12-01T00:00:00Z",
            ],
            "card": [
                "id": "card-id-1",
                "cardNumberEnd": "5123",
                "expirationMonth": cardExpirationMonth,
                "expirationYear": cardExpirationYear,
                "token": cardToken,
                "embossName": cardEmbossName,
                "cardType": "PHYSICAL",
                "cardStatus": "ACTIVE",
                "isPinSet": cardIsPinSet,
            ],
            "depositAddress": "0xDEPOSITADDRESS",
        ]

        return try decode(json)
    }

    static func minimal() throws -> VisaCustomerInfoResponse {
        let json: [String: Any] = [
            "id": "customer-id-min",
            "state": "NEW",
            "createdAt": "2026-01-01T00:00:00Z",
        ]

        return try decode(json)
    }

    private static func decode(_ json: [String: Any]) throws -> VisaCustomerInfoResponse {
        let data = try JSONSerialization.data(withJSONObject: json)
        return try makeDecoder().decode(VisaCustomerInfoResponse.self, from: data)
    }
}
