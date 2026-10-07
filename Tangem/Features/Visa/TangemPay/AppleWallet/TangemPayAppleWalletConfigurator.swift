//
//  TangemPayAppleWalletConfigurator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import MeaPushProvisioning
import TangemFoundation

struct TangemPayAppleWalletConfigurator: Initializable {
    func initialize() {
        MeaPushProvisioning.setDebugLoggingEnabled(AppEnvironment.current.isInternalOrDebug)

        MeaPushProvisioning.loadConfig("mea_config")
    }
}
