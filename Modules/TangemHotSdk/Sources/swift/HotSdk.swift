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
    /// - Returns: The identifier of the newly created wallet as `UserWalletId`.
    /// - Throws: An error if wallet generation fails.
    func generateWallet() throws -> UserWalletId

    /// Imports a hot wallet using the provided entropy and passphrase.
    /// - Parameters:
    ///   - entropy: The entropy data for wallet generation.
    ///   - passphrase: The passphrase for mnemonic derivation.
    /// - Returns: The identifier of the imported wallet as `UserWalletId`.
    /// - Throws: An error if wallet import fails.
    func importWallet(entropy: Data, passphrase: String) throws -> UserWalletId

    /// Validates the authentication data for a hot wallet and returns the wallet context.
    /// - Parameters:
    ///   - auth: The authentication data required to unlock the wallet.
    ///   - walletID: The identifier of the wallet to validate.
    /// - Returns: A `MobileWalletContext` containing the authentication context for the wallet.
    /// - Throws: An error if validation fails, such as if the wallet is missing or authentication is incorrect.
    func validate(auth: AuthenticationUnlockData, for walletID: UserWalletId) throws -> MobileWalletContext

    /// Exports the mnemonic phrase for a hot wallet.
    /// - Parameter context: The wallet context containing authentication information.
    /// - Returns: An array of mnemonic words for the wallet.
    /// - Throws: An error if export fails or authentication is invalid.
    func exportMnemonic(context: MobileWalletContext) throws -> [String]

    /// Exports the backup data for a hot wallet.
    /// - Parameter context: The wallet context containing authentication information.
    /// - Returns: Backup data for the wallet as `Data`.
    /// - Throws: An error if export fails or authentication is invalid.
    func exportBackup(context: MobileWalletContext) throws -> Data

    /// Deletes hot wallets from storage.
    /// - Parameter walletID: The identifiers of the wallets to delete.
    /// - Throws: An error if deleting fails, such as if the wallet is missing
    func delete(walletIDs: [UserWalletId]) throws

    /// Updates the access code for a hot wallet.
    /// - Parameters:
    ///  - newAccessCode: The new access code to set for the wallet.
    ///  - enableBiometrics: A boolean indicating whether to enable biometric authentication.
    ///  - seedKey: The seed key to store under new access code
    ///  - context: The wallet context containing current authentication information.
    /// - Throws: An error if the access code update fails, such as if authentication is incorrect or the wallet is missing.
    func updateAccessCode(
        _ newAccessCode: String,
        enableBiometrics: Bool,
        seedKey: Data,
        context: MobileWalletContext
    ) throws

    /// Refreshes biometric authentication for a hot wallet.
    /// - Parameters:
    ///   - context: The wallet context containing authentication information.
    /// - Throws: An error if refreshing biometrics fails, such as if the wallet is missing or authentication is incorrect.
    func refreshBiometrics(context: MobileWalletContext) throws

    /// This method will remove the biometric authentication data for the specified wallets.
    /// - Parameter walletIDs: wallets to clear biometrics for.
    func clearBiometrics(walletIDs: [UserWalletId])

    /// Derives master keys for a hot wallet.
    /// - Parameter context: The wallet context containing authentication information.
    /// - Returns: A `HotWallet` object containing the derived master keys.
    /// - Throws: An error if key derivation fails or authentication is invalid.
    func deriveMasterKeys(context: MobileWalletContext) throws -> HotWallet

    /// Derives keys for a hot wallet based on specified derivation paths.
    /// - Parameters:
    ///   - context: The wallet context containing authentication information.
    ///   - derivationPaths: A dictionary mapping public key data to their respective derivation paths.
    /// - Returns: A dictionary mapping public keys (`Data`) to `HotWalletKeyInfo` objects.
    /// - Throws: An error if key derivation fails or authentication is invalid.
    func deriveKeys(
        context: MobileWalletContext,
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
        context: MobileWalletContext
    ) throws -> [Data: [Data]]

    /// Retrieves the public data encryption key for a hot wallet.
    /// - Parameter context: The wallet context containing authentication information.
    /// - Returns: The public data encryption key as `UserWalletEncryptionKey`.
    /// - Throws: An error if the key retrieval fails, such as if the wallet is missing or the context is corrupted.
    func userWalletEncryptionKey(context: MobileWalletContext) throws -> UserWalletEncryptionKey
}
