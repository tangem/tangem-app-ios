//
//  StakingPendingHashesSender.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public protocol StakingPendingHashesSender {
    func sendHash(_ pendingHash: StakingPendingHash) async throws

    func sendHashesIfNeeded()
}
