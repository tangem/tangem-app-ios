//
//  TangemPayAppleWalletConfigurator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
#if canImport(MeaPushProvisioning)
import MeaPushProvisioning
#endif

struct TangemPayAppleWalletConfigurator: Initializable {
    func initialize() {
        #if canImport(MeaPushProvisioning)
        MeaPushProvisioning.setDebugLoggingEnabled(AppEnvironment.current.isInternalOrDebug)

        MeaPushProvisioning.loadConfig("mea_config")
        #endif
    }
}
