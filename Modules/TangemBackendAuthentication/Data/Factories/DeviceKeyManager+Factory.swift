//
//  DeviceKeyManager+Factory.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

private import enum CryptoKit.SecureEnclave

// [REDACTED_TODO_COMMENT]

public extension DeviceKeyManager {
    static let `default`: DeviceKeyManager = {
        let keychainService = "com.tangem.backendAuthentication"
        let keychainAccount = "deviceKey"

        let keychainRepository = SecurityKeychainRepository(keychainService: keychainService, keychainAccount: keychainAccount)
        let devicePrivateKeyRepository = SecureEnclaveDevicePrivateKeyRepository(keychainRepository: keychainRepository)

        return DeviceKeyManager(privateKeyRepository: devicePrivateKeyRepository)
    }()
}
