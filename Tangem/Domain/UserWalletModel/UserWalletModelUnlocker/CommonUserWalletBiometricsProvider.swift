//
//  CommonUserWalletBiometricsProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import LocalAuthentication
import TangemLocalization
import TangemSdk

final class CommonUserWalletBiometricsProvider: UserWalletBiometricsProvider {
    func unlock() async throws -> LAContext {
        try await BiometricsUtil.requestAccess(localizedReason: Localization.biometryTouchIdReason)
    }
}
