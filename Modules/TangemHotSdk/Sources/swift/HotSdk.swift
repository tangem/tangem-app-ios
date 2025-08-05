//
//  HotSdk.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import LocalAuthentication
import TangemFoundation

public protocol HotSdk {
    /// Generates a new hot wallet.
    /// - Returns: The identifier of the newly created wallet.
    /// - Throws: An error if wallet generation fails.
    func generateWallet() throws -> UserWalletId

    /// Imports a hot wallet using the provided entropy and passphrase.
    /// - Parameters:
    ///   - entropy: The entropy data for wallet generation.
    ///   - passphrase: The passphrase for mnemonic derivation.
    /// - Returns: The identifier of the imported wallet.
    /// - Throws: An error if wallet import fails.
    func importWallet(entropy: Data, passphrase: String) throws -> UserWalletId

    /// Exports the mnemonic phrase for a hot wallet.
    /// - Parameters:
    ///   - walletID: The identifier of the wallet to export.
    ///   - auth: The authentication data required to unlock the wallet.
    /// - Returns: An array of mnemonic words.
    /// - Throws: An error if export fails.
    func exportMnemonic(walletID: UserWalletId, auth: AuthenticationUnlockData) throws -> [String]

    /// Exports the backup data for a hot wallet.
    /// - Parameters:
    ///   - walletID: The identifier of the wallet to export.
    ///   - auth: The authentication data required to unlock the wallet.
    /// - Returns: Backup data for the wallet.
    /// - Throws: An error if export fails.
    func exportBackup(walletID: UserWalletId, auth: AuthenticationUnlockData) throws -> Data

    /// Deletes a hot wallet.
    /// - Parameter id: The identifier of the wallet to delete.
    /// - Throws: An error if deletion fails.
    func delete(id: UserWalletId) throws

    /// Updates the access code for a hot wallet.
    /// - Parameters:
    ///   - newAccessCode: The new access code to set for the wallet.
    ///   - oldAuth: The current authentication data
    ///   - walletID: The identifier of the wallet for which the access code is being updated.
    /// - Throws: An error if the access code update fails, such as if the old authentication data is incorrect or if the wallet is missing.
    func updateAccessCode(_ newAccessCode: String, oldAuth: AuthenticationUnlockData, for walletID: UserWalletId) throws

    /// Enables biometrics for a hot wallet.
    /// - Parameters:
    ///   - walletID: The identifier of the wallet for which biometrics are being enabled.
    ///   - accessCode: The access code to unlock encrypted data before enabling biometrics.
    /// - Throws: An error if enabling biometrics fails, such as if the wallet is missing or the access code is incorrect.
    func enableBiometrics(for walletID: UserWalletId, accessCode: String) throws

    /// Derives master keys for a hot wallet.
    /// - Parameters:
    ///   - walletID: The identifier of the wallet for which master keys are being derived.
    ///   - auth: The authentication data used to unlock the wallet, such as an access code or biometrics.
    /// - Returns: A `HotWallet` object containing the derived master keys.
    /// - Throws: An error if key derivation fails.
    func deriveMasterKeys(walletID: UserWalletId, auth: AuthenticationUnlockData) throws -> HotWallet

    /// Derives keys for a hot wallet based on specified derivation paths.
    /// - Parameters:
    ///   - walletID: The identifier of the wallet for which keys are being derived.
    ///   - auth: The authentication data used to unlock the wallet, such as an access code or biometrics.
    ///   - derivationPaths: A dictionary mapping key types to their respective derivation paths.
    /// - Returns: A dictionary mapping public keys to `HotWalletKeyInfo` objects.
    /// - Throws: An error if key derivation fails.
    func deriveKeys(
        walletID: UserWalletId,
        auth: AuthenticationUnlockData,
        derivationPaths: [Data: [DerivationPath]]
    ) throws -> [Data: HotWalletKeyInfo]

    /// Signs data using the provided seed key and wallet ID.
    /// - Parameters:
    ///  - dataToSign: An array of `SignData` objects containing the data to sign.
    ///  - seedKey: The seed key used for signing.
    ///  - walletID: The identifier of the wallet used for signing.
    ///  - auth: The authentication data used to unlock the wallet, such as an access
    ///  code or biometrics.
    ///  - Throws: An error if signing fails, such as if the wallet is missing or the authentication data is incorrect.
    func sign(
        dataToSign: [SignData],
        seedKey: Data,
        walletID: UserWalletId,
        auth: AuthenticationUnlockData
    ) throws -> [Data: [Data]]
}
