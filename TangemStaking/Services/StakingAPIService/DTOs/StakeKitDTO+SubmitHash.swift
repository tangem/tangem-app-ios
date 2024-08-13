//
//  StakeKitDTO+SubmitHash.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

extension StakeKitDTO {
    enum SubmitHash {
        struct Request: Encodable {
            let hash: String
        }
    }
}
