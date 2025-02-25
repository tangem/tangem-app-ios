//
//  VisaBFFUtility.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import JWTDecode

struct VisaBFFUtility {
    func getEssentialBFFIds(from accessToken: String) throws -> (customerId: String, productInstanceId: String) {
        let jwtToken = try decode(jwt: accessToken)
        return try getEssentialBFFIds(from: jwtToken)
    }

    func getEssentialBFFIds(from accessToken: JWT) throws -> (customerId: String, productInstanceId: String) {
        let jwtHelper = JWTTokenHelper()
        guard
            let customerId = jwtHelper.getCustomerID(from: accessToken),
            let productInstanceId = jwtHelper.getProductInstanceID(from: accessToken)
        else {
            throw VisaActivationError.missingCustomerInformationInAccessToken
        }

        return (customerId, productInstanceId)
    }
}
