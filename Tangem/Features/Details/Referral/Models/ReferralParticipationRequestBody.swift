//
//  ReferralParticipationRequestBody.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Moya

struct ReferralParticipationRequestBody: Encodable {
    let walletId: String
    let networkId: String
    let tokenId: String
    let address: String
}
