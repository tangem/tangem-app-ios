//
//  YieldBoostPromotionDTO.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum YieldBoostPromotionDTO {}

extension YieldBoostPromotionDTO {
    struct Request: Encodable {
        let walletId: String
    }

    struct Response: Decodable {
        let promoEnrollmentStatus: PromoEnrollmentStatus
        // The fields below are present only after the user enrolls — they are `null` while
        // `promoEnrollmentStatus == .notStarted`.
        let tokenName: String?
        let networkId: String?
        let moduleAddress: String?
        let userAddress: String?
        let contractAddress: String?
        let activationDate: Date?
        let qualificationEndDate: Date?
        let disqualificationReason: DisqualificationReason?
    }

    enum PromoEnrollmentStatus: String, Decodable {
        case notStarted
        case active
        case completed
        case disqualified
    }

    enum DisqualificationReason: String, Decodable {
        case fraud
        case less1Usd
        case closed
    }
}
