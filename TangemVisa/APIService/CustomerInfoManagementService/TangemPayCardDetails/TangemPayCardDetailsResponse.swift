//
//  TangemPayCardDetailsResponse.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

public struct TangemPayCardDetailsResponse: Decodable {
    public struct Secret: Decodable {
        public let secret: String
        public let iv: String
    }

    public let expirationMonth: String
    public let expirationYear: String
    public let pan: Secret
    public let cvv: Secret

    @DefaultIfMissing
    public var isPINSet: Bool
}
