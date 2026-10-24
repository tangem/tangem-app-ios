//
//  TangemPayJoinWaitlistRequest.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct TangemPayJoinWaitlistRequest: Encodable {
    public let email: String
    public let product: TangemPayProduct
    public let countryCode: String
    public let regionCode: String?
    public let marketingConsent: Bool

    public init(
        email: String,
        product: TangemPayProduct,
        countryCode: String,
        regionCode: String?,
        marketingConsent: Bool
    ) {
        self.email = email
        self.product = product
        self.countryCode = countryCode
        self.regionCode = regionCode
        self.marketingConsent = marketingConsent
    }
}
