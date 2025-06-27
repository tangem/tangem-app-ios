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
    private let walletInfoEncryptionStorage: WalletInfoEncryptionStorage

    public init(secureStorage: SecureStorage, biometricsStorage: BiometricsStorage) {
        privateInfoStorage = PrivateInfoStorage(secureStorage: secureStorage, biometricsStorage: biometricsStorage)
        walletInfoEncryptionStorage = WalletInfoEncryptionStorage(secureStorage: secureStorage)
    }

    public func importWallet(entropy: Data, passphrase: String?, auth: HotAuth?) throws -> HotWalletID {
        let authType: HotWalletID.AuthType? = {
            switch auth {
            case .password: return .password
            case .biometry: return .biometry
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

    public func storeEncryptionKey(id: HotWalletID, password: String, encryptionKey: Data) throws {
        try walletInfoEncryptionStorage.store(walletID: id, password: password, data: encryptionKey)
    }

    public func getEncryptionKey(id: HotWalletID, password: String) throws -> Data? {
        try walletInfoEncryptionStorage.get(walletID: id, password: password)
    }
}
