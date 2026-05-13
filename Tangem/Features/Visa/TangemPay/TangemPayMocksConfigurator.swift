//
//  TangemPayMocksConfigurator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct TangemPayMocksConfigurator: Initializable {
    func initialize() {
        guard AppEnvironment.current.isUITest,
              FeatureStorage.instance.visaAPIType == .mock else {
            return
        }
        InjectedValues[\.tangemPayAssembly] = MockTangemPayAssembly()
        InjectedValues[\.tangemPayAuthorizationTokensRepository] = MockTangemPayAuthorizationTokensRepository()
    }
}
