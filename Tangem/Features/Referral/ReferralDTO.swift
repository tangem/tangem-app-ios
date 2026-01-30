//
//  ReferralDTO.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

enum ReferralDTO {
    struct Request: Encodable {
        let walletIds: [String]
        let referralCode: String
        let utmCampaign: String?
    }
}
