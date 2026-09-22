//
//  UserWalletBiometricsProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import LocalAuthentication

protocol UserWalletBiometricsProvider {
    func unlock() async throws -> LAContext
}
