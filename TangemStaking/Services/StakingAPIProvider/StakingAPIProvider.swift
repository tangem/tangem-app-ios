//
//  StakingAPIProvider.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public protocol StakingAPIProvider {
    func enabledYields() async throws -> [YieldInfo]
    func yieldInfo(integrationId: String) async throws -> YieldInfo

    func enterAction(amount: Decimal, address: String, validator: String, integrationId: String) async throws
}
