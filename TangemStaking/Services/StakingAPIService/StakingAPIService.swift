//
//  StakingAPIService.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol StakingAPIService {
    func getStakingInfo(wallet: StakingWallet) async throws -> StakingInfo
}
