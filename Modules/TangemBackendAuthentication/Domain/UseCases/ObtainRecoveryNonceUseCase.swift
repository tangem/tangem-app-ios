//
//  ObtainRecoveryNonceUseCase.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct Foundation.Data

package struct ObtainRecoveryNonceUseCase: Sendable {
    private let registerDevice: RegisterDevice
    private let deviceKeyManager: DeviceKeyManager
    private let nonceDecryptor: any NonceDecryptor
    private let recoveryClient: any UserWalletRecoveryClient

    init(
        registerDevice: @escaping RegisterDevice,
        deviceKeyManager: DeviceKeyManager,
        nonceDecryptor: some NonceDecryptor,
        recoveryClient: some UserWalletRecoveryClient
    ) {
        self.registerDevice = registerDevice
        self.deviceKeyManager = deviceKeyManager
        self.nonceDecryptor = nonceDecryptor
        self.recoveryClient = recoveryClient
    }

    package func callAsFunction() async throws(ObtainRecoveryNonceError) -> String {
        do {
            _ = try await registerDevice()
        } catch {
            throw ObtainRecoveryNonceError.deviceRegistrationFailure(error)
        }

        let devicePublicKey: DevicePublicKey
        do {
            devicePublicKey = try await deviceKeyManager.publicKey
        } catch {
            throw ObtainRecoveryNonceError.deviceKeyFailure(error)
        }

        let cipheredNonce: String
        do {
            cipheredNonce = try await recoveryClient.requestCipheredNonce(devicePublicKey: devicePublicKey)
        } catch {
            throw ObtainRecoveryNonceError.clientFailure(error)
        }

        let decryptedNonce: Data
        do {
            decryptedNonce = try nonceDecryptor.decrypt(cipheredNonce: cipheredNonce)
        } catch {
            throw ObtainRecoveryNonceError.nonceDecryptionFailure(error)
        }

        return String(decoding: decryptedNonce, as: UTF8.self)
    }
}
