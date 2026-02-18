//
//  ExpressDestinationNotificationProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk

protocol ExpressDestinationNotificationProvider {
    func validate(destination: String) async -> ValidationError?
}
