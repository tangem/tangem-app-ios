//
//  DefaultTangemHotSdk.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import LocalAuthentication
import TangemFoundation

public final class CommonHotSdk: HotSdk {
    private let privateInfoStorageManager: PrivateInfoStorageManager

    public init() {
        privateInfoStorageManager = PrivateInfoStorageManager(
            privateInfoStorage: PrivateInfoStorage(),
            encryptionKeySecureStorage: EncryptionKeySecureStorage(),
            encryptionKeyBiometricsStorage: EncryptionKeyBiometricsStorage()
        )
    }

    public func importWallet(entropy: Data, passphrase: String) throws -> UserWalletId {
        let masterKeys = try deriveMasterKeys(entropy: entropy, passphrase: passphrase)

        guard let walletID = masterKeys.first(where: { $0.curve == .secp256k1 })?.publicKey else {
            throw HotWalletError.failedToDeriveKey
        }

        let userWalletId = UserWalletId(with: walletID)

        try privateInfoStorageManager.storeUnsecured(
            privateInfoData: PrivateInfo(entropy: entropy, passphrase: passphrase).encode(),
            walletID: userWalletId
        )
        return userWalletId
    }

    public func generateWallet() throws -> UserWalletId {
        let entropy = try CryptoUtils.generateRandomBytes(count: 32) // 256 bits of entropy

        return try importWallet(entropy: entropy, passphrase: "")
    }

    public func validate(auth: AuthenticationUnlockData, for walletID: UserWalletId) throws -> MobileWalletContext {
        try privateInfoStorageManager.validate(auth: auth, for: walletID)
    }

    public func exportMnemonic(context: MobileWalletContext) throws -> [String] {
        let privateInfo = try privateInfoStorageManager.getPrivateInfoData(context: context)

        guard let privateInfo = PrivateInfo(data: privateInfo) else {
            throw HotWalletError.failedToExportMnemonic
        }

        let mnemonic = try Mnemonic(entropyData: privateInfo.entropy, wordList: .en)

        return mnemonic.mnemonicComponents
    }

    public func exportBackup(context: MobileWalletContext) throws -> Data {
        // Placeholder for backup export logic
        return Data()
    }

    public func delete(id: UserWalletId) throws {
        try privateInfoStorageManager.delete(hotWalletID: id)
    }

    public func updateAccessCode(
        _ newAccessCode: String,
        context: MobileWalletContext
    ) throws {
        try privateInfoStorageManager.updateAccessCode(newAccessCode, context: context)
    }

    public func enableBiometrics(
        context: MobileWalletContext,
        laContext: LAContext
    ) throws {
        try privateInfoStorageManager.enableBiometrics(context: context, laContext: laContext)
    }

    public func deriveMasterKeys(context: MobileWalletContext) throws -> HotWallet {
        let privateInfo = try privateInfoStorageManager.getPrivateInfoData(context: context)

        guard let privateInfo = PrivateInfo(data: privateInfo) else {
            throw HotWalletError.failedToDeriveKey
        }

        defer {
            privateInfo.clear()
        }

        let keyInfos = try deriveMasterKeys(
            entropy: privateInfo.entropy,
            passphrase: privateInfo.passphrase
        )

        return HotWallet(id: context.walletID, wallets: keyInfos)
    }

    public func deriveKeys(
        context: MobileWalletContext,
        derivationPaths: [Data: [DerivationPath]]
    ) throws -> [Data: HotWalletKeyInfo] {
        let privateInfo = try privateInfoStorageManager.getPrivateInfoData(context: context)

        guard let privateInfo = PrivateInfo(data: privateInfo) else {
            throw HotWalletError.failedToDeriveKey
        }

        defer {
            privateInfo.clear()
        }

        var result = [Data: HotWalletKeyInfo]()

        let masterKeys = try deriveMasterKeys(
            entropy: privateInfo.entropy,
            passphrase: privateInfo.passphrase
        )

        try derivationPaths.forEach { masterKey, derivationPaths in
            guard let masterKeyInfo = masterKeys.first(where: { $0.publicKey == masterKey }) else {
                throw HotWalletError.failedToDeriveKey
            }

            var keyInfo = HotWalletKeyInfo(
                publicKey: masterKeyInfo.publicKey,
                chainCode: masterKeyInfo.chainCode,
                curve: masterKeyInfo.curve
            )

            try derivationPaths.forEach { path in
                let derivedPublicKey = try DerivationUtil.deriveKeys(
                    entropy: privateInfo.entropy,
                    passphrase: privateInfo.passphrase,
                    derivationPath: path,
                    curve: masterKeyInfo.curve
                )

                var derivedKeys = keyInfo.derivedKeys
                derivedKeys[path] = derivedPublicKey

                keyInfo.derivedKeys = derivedKeys
            }

            result[keyInfo.publicKey] = keyInfo
        }

        return result
    }

    public func publicDataEncryptionKeyData(context: MobileWalletContext) throws -> Data {
        let privateInfo = try privateInfoStorageManager.getPrivateInfoData(context: context)

        guard let privateInfo = PrivateInfo(data: privateInfo) else {
            throw HotWalletError.failedToDeriveKey
        }

        defer {
            privateInfo.clear()
        }

        let masterKeys = try deriveMasterKeys(
            entropy: privateInfo.entropy,
            passphrase: privateInfo.passphrase,
            curves: [.secp256k1]
        )

        guard let secp256k1Key = masterKeys.first else {
            throw HotWalletError.failedToDeriveKey
        }

        return secp256k1Key.publicKey
    }
}

private extension CommonHotSdk {
    func deriveMasterKeys(
        entropy: Data,
        passphrase: String,
        curves: [EllipticCurve] = EllipticCurve.allCases
    ) throws -> [HotWalletKeyInfo] {
        try curves.compactMap { curve -> HotWalletKeyInfo? in
            let publicKey: ExtendedPublicKey
            switch curve {
            case .bls12381_G2_AUG:
                publicKey = try BLSUtil.publicKey(entropy: entropy, passphrase: passphrase)
            case .secp256k1, .ed25519, .ed25519_slip0010:
                publicKey = try DerivationUtil.deriveKeys(
                    entropy: entropy,
                    passphrase: passphrase,
                    derivationPath: nil,
                    curve: curve
                )
            default:
                return nil
            }

            return HotWalletKeyInfo(
                publicKey: publicKey.publicKey,
                chainCode: publicKey.chainCode,
                curve: curve
            )
        }
    }
}
