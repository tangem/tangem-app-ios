//
//  TangemProviderConfiguration+Collectibles.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemNetworkUtils

extension TangemProviderConfiguration {
    static let collectibles = TangemProviderConfiguration(
        urlSessionConfiguration: .ephemeralConfiguration,
        headerValues: [
            APIHeaderKeyInfo(headerName: "session-id", headerValue: AppConstants.sessionId),
        ]
    )
}
