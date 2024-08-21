//
//  StakingPendingHashesRepository.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public protocol StakingPendingHashesRepository {
    func storeHash(_ hash: StakingPendingHash)
    func fetchHashes() -> [StakingPendingHash]
    func removeHash(_ hash: StakingPendingHash)
}
