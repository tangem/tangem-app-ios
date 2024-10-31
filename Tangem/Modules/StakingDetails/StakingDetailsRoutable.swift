//
//  StakingDetailsRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking

protocol StakingDetailsRoutable: AnyObject {
    func openStakingFlow()
    func openMultipleRewards()
    func openUnstakingFlow(action: UnstakingModel.Action)
    func openRestakingFlow(action: RestakingModel.Action)
    func openStakingSingleActionFlow(action: StakingSingleActionModel.Action)
    func openWhatIsStaking()
}
