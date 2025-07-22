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

    public func importWallet(entropy: Data, passphrase: String, auth: Authentication) throws -> HotWalletID {
        let walletID = HotWalletID()

        try privateInfoStorage.store(
            privateInfoData: PrivateInfo(entropy: entropy, passphrase: passphrase).encode(),
            for: walletID,
            auth: auth
        )
        return walletID
    }

    public func generateWallet(auth: Authentication) throws -> HotWalletID {
        let entropy = try CryptoUtils.generateRandomBytes(count: 32) // 256 bits of entropy

        return try importWallet(entropy: entropy, passphrase: "", auth: auth)
    }

    public func exportMnemonic(walletID: HotWalletID, auth: AuthenticationUnlockData) throws -> PrivateInfo {
        let privateInfo = try privateInfoStorage.getPrivateInfoData(for: walletID, auth: auth)
        guard let privateInfo = PrivateInfo(data: privateInfo) else {
            throw HotWalletError.failedToExportMnemonic
        }
        
        return privateInfo
    }

    public func exportBackup(walletID: HotWalletID, auth: AuthenticationUnlockData) throws -> Data {
        // Placeholder for backup export logic
        return Data()
    }

    public func delete(id: HotWalletID) throws {
        try privateInfoStorage.delete(hotWalletID: id)
    }
    
    public func updateAuthentication(
        _ newAuth: Authentication?,
        oldAuth: AuthenticationUnlockData?,
        for walletID: HotWalletID
    ) throws {
        try privateInfoStorage.updateStore(walletID: walletID, oldAuth: oldAuth, newAuth: newAuth)
    }
}
