//
//  TangemPayBiometryAuthorizer.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemLocalization
import TangemSdk

protocol TangemPayBiometryAuthorizer {
    var isAvailable: Bool { get }

    func requestAccess() async throws
}

struct CommonTangemPayBiometryAuthorizer: TangemPayBiometryAuthorizer {
    var isAvailable: Bool {
        BiometricsUtil.isAvailable
    }

    func requestAccess() async throws {
        _ = try await BiometricsUtil.requestAccess(localizedReason: Localization.biometryTouchIdReason)
    }
}
