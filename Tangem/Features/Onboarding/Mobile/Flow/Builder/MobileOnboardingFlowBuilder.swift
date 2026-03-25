//
//  MobileOnboardingFlowBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemUI

class MobileOnboardingFlowBuilder: StepsFlowBuilder {
    let hasProgressBar: Bool

    init(hasProgressBar: Bool) {
        self.hasProgressBar = hasProgressBar
        super.init()
    }
}
