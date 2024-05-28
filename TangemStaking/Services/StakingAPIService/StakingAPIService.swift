//
//  StakingAPIService.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol StakingAPIService {
    func enabledYields() async throws -> StakeKitDTO.Yield.Enabled.Response
    func getYield(request: StakeKitDTO.Yield.Info.Request) async throws -> StakeKitDTO.Yield.Info.Response

    func enterAction(request: StakeKitDTO.Actions.Enter.Request) async throws -> StakeKitDTO.Actions.Enter.Response
}
