//
//  TangemPayJoinWaitlistRequest.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public struct TangemPayJoinWaitlistRequest: Encodable {
    public let email: String
    public let product: TangemPayProduct
    public let country: String
    public let region: String?
    public let marketingConsent: Bool

    public init(
        email: String,
        product: TangemPayProduct,
        country: String,
        region: String?,
        marketingConsent: Bool
    ) {
        self.email = email
        self.product = product
        self.country = country
        self.region = region
        self.marketingConsent = marketingConsent
    }
}
