//
//  HotBiometricsSecureEnclaveService.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import LocalAuthentication

protocol HotBiometricsSecureEnclaveService {
    func encryptData(_ data: Data, keyTag: String, context: LAContext?) throws -> Data
    func decryptData(_ data: Data, keyTag: String, context: LAContext) throws -> Data
}

extension BiometricsSecureEnclaveService: HotBiometricsSecureEnclaveService {}
