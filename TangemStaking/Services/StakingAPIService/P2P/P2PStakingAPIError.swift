//
//  P2PStakingAPIError.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

enum P2PStakingAPIError: Error {
    case apiError(P2PDTO.APIError)
}
