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

        // Synthetic tokens skip the key derivation a withdrawal is signed with, so signing tests opt out of them.
        guard !ProcessInfo.processInfo.arguments.contains(Constants.realAuthorizationArgument) else {
            return
        }

        InjectedValues[\.tangemPayAuthorizationTokensRepository] = MockTangemPayAuthorizationTokensRepository()
    }
}

extension TangemPayMocksConfigurator {
    enum Constants {
        static let realAuthorizationArgument = "-uitest-tangempay-real-authorization"
    }
}
