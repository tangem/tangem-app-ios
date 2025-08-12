//
//  PublicInfoStorageManager.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import LocalAuthentication

final class PublicInfoStorageManager {
    private let encryptedSecureStorage: EncryptedSecureStorage
    private let encryptedBiometricsStorage: EncryptedBiometricsStorage

    init(encryptedSecureStorage: EncryptedSecureStorage, encryptedBiometricsStorage: EncryptedBiometricsStorage) {
        self.encryptedSecureStorage = encryptedSecureStorage
        self.encryptedBiometricsStorage = encryptedBiometricsStorage
    }
    
    func storePublicData(_ data: Data, context: MobileWalletContext) throws {
        switch context.authentication {
        case .none:
            try encryptedSecureStorage.storeData(
                data,
                keyTag: context.walletID.publicInfoTag,
                secureEnclaveKeyTag: context.walletID.publicInfoSecureEnclaveTag,
                accessCode: nil
            )
        case .accessCode(let accessCode):
            try encryptedSecureStorage.storeData(
                data,
                keyTag: context.walletID.publicInfoTag,
                secureEnclaveKeyTag: context.walletID.publicInfoSecureEnclaveTag,
                accessCode: accessCode
            )
        case .biometrics:
            try encryptedBiometricsStorage.storeData(
                data,
                keyTag: context.walletID.publicInfoBiometricsTag,
                secureEnclaveKeyTag: context.walletID.publicInfoBiometricsSecureEnclaveTag
            )
        }
    }
    
    func publicData(for context: MobileWalletContext) throws -> Data {
        switch context.authentication {
        case .none:
            try encryptedSecureStorage.getData(
                keyTag: context.walletID.publicInfoTag,
                secureEnclaveKeyTag: context.walletID.publicInfoSecureEnclaveTag,
                accessCode: nil
            )
        case .accessCode(let accessCode):
            try encryptedSecureStorage.getData(
                keyTag: context.walletID.publicInfoTag,
                secureEnclaveKeyTag: context.walletID.publicInfoSecureEnclaveTag,
                accessCode: accessCode
            )
        case .biometrics(let laContext):
            try encryptedBiometricsStorage.getData(
                keyTag: context.walletID.publicInfoBiometricsTag,
                secureEnclaveKeyTag: context.walletID.publicInfoBiometricsSecureEnclaveTag,
                context: laContext
            )
        }
    }
    
    func updateAccessCode(
        _ newAccessCode: String,
        context: MobileWalletContext
    ) throws {
        let data = try publicData(for: context)

        try encryptedSecureStorage.storeData(
            data,
            keyTag: context.walletID.publicInfoTag,
            secureEnclaveKeyTag: context.walletID.publicInfoSecureEnclaveTag,
            accessCode: newAccessCode
        )
    }

    func enableBiometrics(
        context: MobileWalletContext
    ) throws {
        let data = try publicData(for: context)

        try encryptedBiometricsStorage.storeData(
            data,
            keyTag: context.walletID.publicInfoBiometricsTag,
            secureEnclaveKeyTag: context.walletID.publicInfoBiometricsSecureEnclaveTag
        )
    }
    
    
    func clearBiometrics(walletIDs: [UserWalletId]) {
        walletIDs.forEach { walletID in
            try? encryptedBiometricsStorage.deleteData(keyTag: walletID.publicInfoBiometricsTag)
        }
    }
    
    func deletePublicData(walletID: UserWalletId) throws {
        var errors = [Error]()

        do {
            try encryptedSecureStorage.deleteData(keyTag: walletID.publicInfoTag)
        } catch {
            errors.append(error)
        }

        // biometrics storage is optional, so we don't throw an error if it fails to delete
        try? encryptedBiometricsStorage.deleteData(keyTag: walletID.publicInfoBiometricsTag)

        if !errors.isEmpty {
            throw CompoundMobileWalletError(underlying: errors)
        }
    }
}
