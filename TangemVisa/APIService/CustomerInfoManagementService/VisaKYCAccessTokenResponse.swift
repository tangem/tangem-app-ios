//
//  VisaKYCAccessTokenResponse.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

public struct VisaKYCAccessTokenResponse: Decodable {
    public let token: String
    public let locale: String
}
