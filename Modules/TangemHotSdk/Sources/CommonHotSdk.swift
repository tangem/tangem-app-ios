//
//  DefaultTangemHotSdk.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

public final class CommonHotSdk: HotSdk {
    private let privateInfoStorage: PrivateInfoStorage

    public init(secureStorage: SecureStorage, biometricsStorage: BiometricsStorage) {
        privateInfoStorage = PrivateInfoStorage(secureStorage: secureStorage, biometricsStorage: biometricsStorage)
    }

    public func importWallet(entropy: Data, passphrase: String?, auth: HotAuth?) throws -> HotWalletID {
        let authType: HotWalletID.AuthType? = {
            switch auth {
            case .password: return .password
            case .biometrics: return .biometrics
            case .none: return nil
            }
        }()

        let newWalletID = HotWalletID(authType: authType)

        guard let walletInfo = HotWalletAuthInfo(walletID: newWalletID, auth: auth) else {
            fatalError()
        }

        try privateInfoStorage.store(
            walletAuthInfo: walletInfo,
            privateInfo: PrivateInfo(entropy: entropy, passphrase: passphrase)
        )
        return newWalletID
    }

    public func generateWallet(auth: HotAuth?) throws -> HotWalletID {
        let entropy = try CryptoUtils.generateRandomBytes(count: 32) // 256 bits of entropy

        return try importWallet(entropy: entropy, passphrase: nil, auth: auth)
    }

    public func exportMnemonic(walletAuthInfo: HotWalletAuthInfo) async throws -> PrivateInfo {
        let container = try privateInfoStorage.getContainer(walletAuthInfo: walletAuthInfo)

        return try await container.call { privateInfo in
            PrivateInfo(
                entropy: privateInfo.entropy,
                passphrase: privateInfo.passphrase
            )
        }
    }

    public func exportBackup(walletAuthInfo: HotWalletAuthInfo) async throws -> Data {
        // Placeholder for backup export logic
        return Data()
    }

    public func delete(id: HotWalletID) async throws {
        try await privateInfoStorage.delete(hotWalletID: id)
    }

    public func changeAuth(walletAuthInfo: HotWalletAuthInfo, auth: HotAuth) async throws {
        try await privateInfoStorage.changeStore(walletAuthInfo: walletAuthInfo, newHotAuth: auth)
    }
}
