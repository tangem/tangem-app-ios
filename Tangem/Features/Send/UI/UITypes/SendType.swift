//
//  SendType.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking

enum SendType {
    case send(parameters: SendParameters)
    case sell(parameters: PredefinedSellParameters)
    case staking(manager: StakingManager)
    case unstaking(manager: StakingManager, action: UnstakingModel.Action)
    case restaking(manager: StakingManager, action: RestakingModel.Action)
    case stakingSingleAction(manager: StakingManager, action: StakingSingleActionModel.Action)
    case onramp(parameters: PredefinedOnrampParameters = .default)
}

// MARK: - Convenience extensions

extension SendType {
    static var send: Self { .send(parameters: .init()) }
}
