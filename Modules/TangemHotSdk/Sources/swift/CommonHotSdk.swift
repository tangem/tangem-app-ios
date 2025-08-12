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
            encryptedSecureStorage: EncryptedSecureStorage(),
            encryptedBiometricsStorage: EncryptedBiometricsStorage()
        )
    }

    public func importWallet(entropy: Data, passphrase: String) throws -> UserWalletId {
        let masterKeys = try deriveMasterKeys(entropy: entropy, passphrase: passphrase)

        guard let walletIdSeed = masterKeys.first(where: { $0.curve == .secp256k1 })?.publicKey else {
            throw HotWalletError.failedToDeriveKey
        }

        let userWalletId = UserWalletId(with: walletIdSeed)

        guard !privateInfoStorageManager.hasPrivateInfoData(for: userWalletId) else {
            throw HotWalletError.walletAlreadyExists
        }

        try storePublicData(for: userWalletId, seedKey: walletIdSeed, accessCode: nil)

        try privateInfoStorageManager.storeUnsecured(
            privateInfoData: PrivateInfo(entropy: entropy, passphrase: passphrase).encode(),
            walletID: userWalletId
        )
        return userWalletId
    }

    public func generateWallet() throws -> UserWalletId {
        let entropy = try CryptoUtils.generateRandomBytes(count: 16) // 128 bits of entropy

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

    public func delete(walletIDs: [UserWalletId]) throws {
        var errors = [Error]()

        walletIDs.forEach { walletID in
            do {
                try privateInfoStorageManager.delete(walletID: walletID)
            } catch {
                errors.append(error)
            }

            let publicDataStorage = EncryptedSecureStorage()

            do {
                try publicDataStorage.deleteData(keyTag: walletID.publicInfoTag)
            } catch {
                errors.append(error)
            }
        }

        if !errors.isEmpty {
            throw CompoundMobileWalletError(underlying: errors)
        }
    }

    public func updateAccessCode(
        _ newAccessCode: String,
        context: MobileWalletContext
    ) throws {
        try privateInfoStorageManager.updateAccessCode(newAccessCode, context: context)

        let seedKey = try publicData(for: context)

        try storePublicData(
            for: context.walletID,
            seedKey: seedKey,
            accessCode: newAccessCode
        )
    }

    public func enableBiometrics(
        context: MobileWalletContext
    ) throws {
        try privateInfoStorageManager.enableBiometrics(context: context)
    }

    public func clearBiometrics(walletIDs: [UserWalletId]) {
        privateInfoStorageManager.clearBiometrics(walletIDs: walletIDs)
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

            var derivedKeys = keyInfo.derivedKeys ?? [:]

            try derivationPaths.forEach { path in
                guard derivedKeys[path] == nil else {
                    // If the key for this path is already derived, skip it
                    return
                }
                let derivedPublicKey = try DerivationUtil.deriveKeys(
                    entropy: privateInfo.entropy,
                    passphrase: privateInfo.passphrase,
                    derivationPath: path,
                    curve: masterKeyInfo.curve
                )

                derivedKeys[path] = derivedPublicKey
            }

            keyInfo.derivedKeys = derivedKeys

            result[keyInfo.publicKey] = keyInfo
        }

        return result
    }

    public func userWalletEncryptionKey(context: MobileWalletContext) throws -> UserWalletEncryptionKey {
        let seedKey = try publicData(for: context)

        return UserWalletEncryptionKey(userWalletIdSeed: seedKey)
    }

    public func sign(
        dataToSign: [SignData],
        seedKey: Data,
        context: MobileWalletContext
    ) throws -> [Data: [Data]] {
        let privateInfo = try privateInfoStorageManager.getPrivateInfoData(context: context)

        guard let privateInfo = PrivateInfo(data: privateInfo) else {
            throw HotWalletError.failedToDeriveKey
        }

        defer {
            privateInfo.clear()
        }

        let curves: [Data: EllipticCurve] = dataToSign.reduce(into: [:]) { partialResult, signData in
            let curve = DerivationUtil.curve(
                for: seedKey,
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
    func storePublicData(for userWalletId: UserWalletId, seedKey: Data, accessCode: String?) throws {
        let publicDataStorage = EncryptedSecureStorage()
        try publicDataStorage.storeData(
            seedKey,
            keyTag: userWalletId.publicInfoTag,
            secureEnclaveKeyTag: userWalletId.publicInfoSecureEnclaveTag,
            accessCode: accessCode
        )
    }

    func publicData(for context: MobileWalletContext) throws -> Data {
        let accessCode: String? = switch context.authentication {
        case .accessCode(let code): code
        case .none: nil
        case .biometrics: throw HotWalletError.accessCodeIsRequired
        }
        let publicDataStorage = EncryptedSecureStorage()

        return try publicDataStorage.getData(
            keyTag: context.walletID.publicInfoTag,
            secureEnclaveKeyTag: context.walletID.publicInfoSecureEnclaveTag,
            accessCode: accessCode
        )
    }

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
