//
//  Responses.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

struct RegistrationResponse: Codable, ErrorContainer {
    let results: [RegistrationResponse.Item]
    let error: String?
    let errorCode: Int?
    let success: Bool
}

extension RegistrationResponse {
    struct Item: Codable, ErrorContainer {
        let cardId: String
        let error: String?
        let passed: Bool?
        let active: Bool?
        let pinSet: Bool?
        let blockchainInit: Bool?
        let kycPassed: Bool?
        let kycProvider: String?
        let kycDate: Date?
        let disabledByAdmin: Bool?

        enum CodingKeys: String, CodingKey {
            case cardId = "CID"
            case error
            case passed
            case active
            case pinSet = "pin_set"
            case blockchainInit = "blockchain_init"
            case kycPassed = "kyc_passed"
            case kycProvider = "kyc_provider"
            case kycDate = "kyc_date"
            case disabledByAdmin = "disabled_by_admin"
        }
    }
}

struct AttestationResponse: Codable, ErrorContainer {
    let challenge: Data
    let error: String?
    let errorCode: Int?
    let success: Bool
}

struct RegisterWalletResponse: Codable, ErrorContainer {
    let error: String?
    let errorCode: Int?
    let success: Bool
}

protocol ErrorContainer {
    var error: String? { get }
}
