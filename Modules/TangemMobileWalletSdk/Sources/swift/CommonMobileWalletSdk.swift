//
//  CommonMobileWalletSdk.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import LocalAuthentication
import TangemFoundation
import CryptoKit

public final class CommonMobileWalletSdk: MobileWalletSdk {
    private let privateInfoStorageManager: PrivateInfoStorageManager
    private let publicInfoStorageManager: PublicInfoStorageManager

    public convenience init() {
        let encryptedSecureStorage = EncryptedSecureStorage()
        let encryptedBiometricsStorage = EncryptedBiometricsStorage()

        self.init(
            privateInfoStorageManager: PrivateInfoStorageManager(
                privateInfoStorage: PrivateInfoStorage(),
                encryptedSecureStorage: encryptedSecureStorage,
                encryptedBiometricsStorage: encryptedBiometricsStorage
            ),
            publicInfoStorageManager: PublicInfoStorageManager(
                encryptedSecureStorage: encryptedSecureStorage
            )
        )
    }

    init(
        privateInfoStorageManager: PrivateInfoStorageManager,
        publicInfoStorageManager: PublicInfoStorageManager
    ) {
        self.privateInfoStorageManager = privateInfoStorageManager
        self.publicInfoStorageManager = publicInfoStorageManager
    }

    public func importWallet(entropy: Data, passphrase: String) throws -> UserWalletId {
        let masterKeys = try deriveMasterKeys(entropy: entropy, passphrase: passphrase)

        guard let seedKey = masterKeys.first(where: { $0.curve == .secp256k1 })?.publicKey else {
            throw MobileWalletError.failedToDeriveKey
        }

        let userWalletId = UserWalletId(with: seedKey)

        try publicInfoStorageManager.storeData(
            UserWalletEncryptionKey(userWalletIdSeed: seedKey).symmetricKey.data,
            walletID: userWalletId,
            accessCode: nil
        )

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
        var privateInfoData = try privateInfoStorageManager.getPrivateInfoData(context: context)
        defer { secureErase(data: &privateInfoData) }

        guard let privateInfo = PrivateInfo(data: privateInfoData) else {
            throw MobileWalletError.failedToExportMnemonic
        }

        defer { privateInfo.clear() }

        let mnemonic = try Mnemonic(entropyData: privateInfo.entropy, wordList: .en)

        return mnemonic.mnemonicComponents
    }

    public func exportPassphrase(context: MobileWalletContext) throws -> String {
        var privateInfoData = try privateInfoStorageManager.getPrivateInfoData(context: context)
        defer { secureErase(data: &privateInfoData) }

        guard let privateInfo = PrivateInfo(data: privateInfoData) else {
            throw MobileWalletError.failedToExportPassphrase
        }

        defer { privateInfo.clear() }

        return privateInfo.passphrase
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

            do {
                try publicInfoStorageManager.deletePublicData(walletID: walletID)
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
        enableBiometrics: Bool,
        seedKey: Data,
        context: MobileWalletContext
    ) throws {
        try privateInfoStorageManager.updateAccessCode(
            newAccessCode,
            enableBiometrics: enableBiometrics,
            context: context,
        )

        let symmetricKeyData = UserWalletEncryptionKey(
            userWalletIdSeed: seedKey
        ).symmetricKey.data

        try publicInfoStorageManager.storeData(
            symmetricKeyData,
            walletID: context.walletID,
            accessCode: newAccessCode
        )
    }

    public func refreshBiometrics(
        context: MobileWalletContext
    ) throws {
        privateInfoStorageManager.clearBiometrics(walletIDs: [context.walletID])
        try privateInfoStorageManager.enableBiometrics(context: context)
    }

    public func isBiometricsEnabled(for walletID: UserWalletId) -> Bool {
        privateInfoStorageManager.isBiometricsEnabled(walletID: walletID)
    }

    public func clearBiometrics(walletIDs: [UserWalletId]) {
        privateInfoStorageManager.clearBiometrics(walletIDs: walletIDs)
    }

    public func deriveMasterKeys(context: MobileWalletContext) throws -> MobileWallet {
        var privateInfoData = try privateInfoStorageManager.getPrivateInfoData(context: context)
        defer { secureErase(data: &privateInfoData) }

        guard let privateInfo = PrivateInfo(data: privateInfoData) else {
            throw MobileWalletError.failedToDeriveKey
        }

        defer { privateInfo.clear() }

        let keyInfos = try deriveMasterKeys(
            entropy: privateInfo.entropy,
            passphrase: privateInfo.passphrase
        )

        return MobileWallet(id: context.walletID, wallets: keyInfos)
    }

    public func deriveKeys(
        context: MobileWalletContext,
        derivationPaths: [Data: [DerivationPath]]
    ) throws -> [Data: MobileWalletKeyInfo] {
        var privateInfoData = try privateInfoStorageManager.getPrivateInfoData(context: context)
        defer { secureErase(data: &privateInfoData) }

        guard let privateInfo = PrivateInfo(data: privateInfoData) else {
            throw MobileWalletError.failedToDeriveKey
        }

        defer { privateInfo.clear() }

        var result = [Data: MobileWalletKeyInfo]()

        let masterKeys = try deriveMasterKeys(
            entropy: privateInfo.entropy,
            passphrase: privateInfo.passphrase
        )

        try derivationPaths.forEach { masterKey, derivationPaths in
            guard let masterKeyInfo = masterKeys.first(where: { $0.publicKey == masterKey }) else {
                throw MobileWalletError.failedToDeriveKey
            }

            var keyInfo = MobileWalletKeyInfo(
                publicKey: masterKeyInfo.publicKey,
                chainCode: masterKeyInfo.chainCode,
                curve: masterKeyInfo.curve
            )

            var derivedKeys = keyInfo.derivedKeys

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

    public func sign(
        dataToSign: [SignData],
        seedKey: Data,
        context: MobileWalletContext
    ) throws -> [MobileWalletSignature] {
        var privateInfoData = try privateInfoStorageManager.getPrivateInfoData(context: context)
        defer { secureErase(data: &privateInfoData) }

        guard let privateInfo = PrivateInfo(data: privateInfoData) else {
            throw MobileWalletError.failedToDeriveKey
        }

        defer { privateInfo.clear() }

        // The curve is a property of the seed key, identical for every `SignData` in the batch.
        guard let curve = DerivationUtil.curve(
            for: seedKey,
            entropy: privateInfo.entropy,
            passphrase: privateInfo.passphrase
        ) else {
            throw MobileWalletError.failedToDeriveKey
        }

        // One signature per input hash, ordered and tagged with its public key. Collapsing by public key
        // drops the signatures of every input but the last when a wallet spends several UTXOs from one
        // address.
        return try dataToSign.flatMap { signData -> [MobileWalletSignature] in
            let signatures: [Data] = switch curve {
            case .bls12381_G2_AUG:
                try BLSUtil.sign(
                    hashes: signData.hashes,
                    entropy: privateInfo.entropy,
                    passphrase: privateInfo.passphrase
                )
            case .secp256k1, .ed25519, .ed25519_slip0010:
                try SignUtil.sign(
                    entropy: privateInfo.entropy,
                    passphrase: privateInfo.passphrase,
                    hashes: signData.hashes,
                    curve: curve,
                    derivationPath: signData.derivationPath
                )
            default:
                throw MobileWalletError.invalidCurve(curve)
            }

            return zip(signData.hashes, signatures).map { hash, signature in
                MobileWalletSignature(publicKey: signData.publicKey, hash: hash, signature: signature)
            }
        }
    }

    public func userWalletEncryptionKey(context: MobileWalletContext) throws -> UserWalletEncryptionKey {
        let accessCode: String? = switch context.authentication {
        case .none: .none
        case .accessCode(let code): code
        case .biometrics: throw MobileWalletError.accessCodeIsRequired
        }

        let symmetricKeyData = try publicInfoStorageManager.data(for: context.walletID, accessCode: accessCode)

        return UserWalletEncryptionKey(symmetricKey: SymmetricKey(data: symmetricKeyData))
    }
}

private extension CommonMobileWalletSdk {
    func deriveMasterKeys(
        entropy: Data,
        passphrase: String,
        curves: [EllipticCurve] = EllipticCurve.allCases
    ) throws -> [MobileWalletKeyInfo] {
        try curves.compactMap { curve -> MobileWalletKeyInfo? in
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

            return MobileWalletKeyInfo(
                publicKey: publicKey.publicKey,
                chainCode: publicKey.chainCode,
                curve: curve
            )
        }
    }
}
