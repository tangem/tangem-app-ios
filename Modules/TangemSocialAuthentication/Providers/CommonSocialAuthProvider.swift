//
//  CommonSocialAuthProvider.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemBackendAuthentication
import TangemMobileWalletBackup
import TangemNetworkUtils
import protocol Alamofire.RequestInterceptor

public final class CommonSocialAuthProvider {
    private let service: SocialAuthAPIService
    private let backupManager: MobileWalletSocialBackupManager

    public init(
        baseURL: URL,
        networkConfiguration: TangemProviderConfiguration,
        requestInterceptor: RequestInterceptor,
        backupManager: MobileWalletSocialBackupManager
    ) {
        let provider = TangemProvider<SocialAuthTarget>(
            configuration: networkConfiguration,
            requestInterceptor: requestInterceptor
        )
        service = CommonSocialAuthAPIService(provider: provider, baseURL: baseURL)
        self.backupManager = backupManager
    }
}

// MARK: - SocialAuthProvider

extension CommonSocialAuthProvider: SocialAuthProvider {
    public func recoverNonce() async throws -> String {
        try await BackendAuthenticationAssembly.obtainRecoveryNonce()
    }

    public func existingWalletBinding(credentials: SocialAuthCredentials) async throws(SocialAuthAPIError) -> SocialAuthWalletBinding? {
        let recoveryEncryptionKey = RecoveryEncryptionKey()
        let metadata = DeviceMetadataDTO.current

        // [REDACTED_TODO_COMMENT]
        let attestationToken: String? = nil
        let appAttestKeyId: String? = nil

        let signaturePayload = DeviceSignaturePayloadFactory.make(
            nonce: credentials.nonce,
            recoveryEncryptionPublicKey: recoveryEncryptionKey.publicKeyBase64,
            providerIdToken: credentials.identityToken,
            attestationToken: attestationToken,
            appAttestKeyId: appAttestKeyId,
            metadata: metadata
        )
        let deviceSignature = try await deviceSignature(for: signaturePayload)

        let request = RecoverWalletDTO.Request(
            nonce: credentials.nonce,
            recoveryEncryptionPublicKey: recoveryEncryptionKey.publicKeyBase64,
            deviceSignature: deviceSignature,
            attestationToken: attestationToken,
            appAttestKeyId: appAttestKeyId,
            providerIdToken: credentials.identityToken,
            metadata: metadata
        )

        do {
            let response = try await service.recoverWallet(request: request)
            return SocialAuthWalletBinding(
                enc: response.enc,
                ct: response.ct,
                recoveryEncryptionKey: recoveryEncryptionKey
            )
        } catch where error.isRecoveryBindingNotFound {
            return nil
        }
    }

    public func encryptRecoveryKey(_ recoveryKey: Data) async throws -> String {
        let publicKey = try await service.recoveryPublicKey()

        return try RecoveryKeyEncryptor().encrypt(
            recoveryKey: recoveryKey,
            publicKey: publicKey
        )
    }

    public func recoverWalletBackup(binding: SocialAuthWalletBinding) async throws -> SocialAuthRecoveredBackup {
        let recoveryKey: Data
        do {
            recoveryKey = try binding.decryptRecoveryKey()
        } catch {
            throw SocialAuthRecoverWalletError.decryptionFailed
        }

        guard let backup = try await backupManager.loadBackup() else {
            throw SocialAuthRecoverWalletError.backupNotFound
        }

        let payload = try await backupManager.importBackup(backup, recoveryKey: recoveryKey)

        return SocialAuthRecoveredBackup(userWalletId: backup.walletId, payload: payload)
    }
}

// MARK: - Private

private extension CommonSocialAuthProvider {
    func deviceSignature(for payload: Data) async throws(SocialAuthAPIError) -> String {
        do {
            let signature = try await BackendAuthenticationAssembly.deviceKeyManager.sign(data: payload)
            return signature.derRepresentation.base64EncodedString()
        } catch {
            throw SocialAuthAPIError.connection(underlying: error)
        }
    }
}
