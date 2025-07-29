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

    public func enableBiometrics(for walletID: UserWalletId, accessCode: String, context: LAContext) throws {
        try privateInfoStorageManager.enableBiometrics(for: walletID, accessCode: accessCode, context: context)
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
        wallet: HotWallet,
        auth: AuthenticationUnlockData,
        derivationPaths: [Data: [DerivationPath]]
    ) throws -> HotWallet {
        let privateInfo = try privateInfoStorageManager.getPrivateInfoData(for: wallet.id, auth: auth)

        guard let privateInfo = PrivateInfo(data: privateInfo) else {
            throw HotWalletError.failedToDeriveKey
        }

        defer {
            privateInfo.clear()
        }

        var wallets: [HotWalletKeyInfo] = wallet.wallets

        try derivationPaths.forEach { masterKey, derivationPaths in
            try derivationPaths.forEach { path in
                let derivedPublicKey = try DerivationUtil.deriveKeys(
                    entropy: privateInfo.entropy,
                    passphrase: privateInfo.passphrase,
                    derivationPath: path,
                    masterKey: masterKey
                )

                guard let walletIndex = wallet.wallets.firstIndex(where: { $0.publicKey == masterKey }) else {
                    return
                }
                wallets[walletIndex].derivedKeys[path] = derivedPublicKey
            }
        }

        return HotWallet(id: wallet.id, wallets: wallets)
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
