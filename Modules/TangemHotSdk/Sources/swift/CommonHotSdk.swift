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

    public func exportMnemonic(walletID: UserWalletId, auth: AuthenticationUnlockData) throws -> [String] {
        let privateInfo = try privateInfoStorageManager.getPrivateInfoData(for: walletID, auth: auth)

        guard let privateInfo = PrivateInfo(data: privateInfo) else {
            throw HotWalletError.failedToExportMnemonic
        }

        let mnemonic = try Mnemonic(entropyData: privateInfo.entropy, wordList: .en)

        return mnemonic.mnemonicComponents
    }

    public func exportBackup(walletID: UserWalletId, auth: AuthenticationUnlockData) throws -> Data {
        // Placeholder for backup export logic
        return Data()
    }

    public func delete(id: UserWalletId) throws {
        try privateInfoStorageManager.delete(hotWalletID: id)
    }

    public func updateAccessCode(
        _ newAccessCode: String,
        oldAuth: AuthenticationUnlockData,
        for walletID: UserWalletId
    ) throws {
        try privateInfoStorageManager.updateAccessCode(newAccessCode, oldAuth: oldAuth, for: walletID)
    }

    public func enableBiometrics(for walletID: UserWalletId, accessCode: String) throws {
        try privateInfoStorageManager.enableBiometrics(for: walletID, accessCode: accessCode)
    }

    public func deriveMasterKeys(walletID: UserWalletId, auth: AuthenticationUnlockData) throws -> HotWallet {
        let privateInfo = try privateInfoStorageManager.getPrivateInfoData(for: walletID, auth: auth)

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

        return HotWallet(id: walletID, wallets: keyInfos)
    }

    public func deriveKeys(
        walletID: UserWalletId,
        auth: AuthenticationUnlockData,
        derivationPaths: [Data: [DerivationPath]]
    ) throws -> [Data: HotWalletKeyInfo] {
        let privateInfo = try privateInfoStorageManager.getPrivateInfoData(for: walletID, auth: auth)

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

    public func sign(
        dataToSign: [SignData],
        seedKey: Data,
        walletID: UserWalletId,
        auth: AuthenticationUnlockData
    ) throws -> [Data: [Data]] {
        let privateInfo = try privateInfoStorageManager.getPrivateInfoData(for: walletID, auth: auth)

        guard let privateInfo = PrivateInfo(data: privateInfo) else {
            throw HotWalletError.failedToDeriveKey
        }

        defer {
            privateInfo.clear()
        }

        let curves: [Data: EllipticCurve] = dataToSign.reduce(into: [:]) { partialResult, signData in
            let curve = DerivationUtil.curve(
                for: signData.publicKey,
                entropy: privateInfo.entropy,
                passphrase: privateInfo.passphrase
            )
            partialResult[signData.publicKey] = curve
        }

        var result = [Data: [Data]]()

        try dataToSign.forEach { dataToSign in
            guard let curve = curves[dataToSign.publicKey] else { return }
            let signedHashes = try SignUtil.sign(
                entropy: privateInfo.entropy,
                passphrase: privateInfo.passphrase,
                hashes: dataToSign.hashes,
                curve: curve,
                derivationPath: dataToSign.derivationPath
            )
            result[dataToSign.publicKey] = signedHashes
        }

        return result
    }
}

private extension CommonHotSdk {
    func deriveMasterKeys(entropy: Data, passphrase: String) throws -> [HotWalletKeyInfo] {
        try EllipticCurve.allCases.compactMap { curve -> HotWalletKeyInfo? in
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
