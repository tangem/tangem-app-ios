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
    func openUnstakingFlow(action: StakingAction)
    func openRestakingFlow(action: StakingAction)
    func openStakingSingleActionFlow(action: StakingAction)
    func openWhatIsStaking()
}
