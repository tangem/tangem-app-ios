//
//  MockWalletInitializer.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

#if DEBUG
import Foundation
import TangemSdk
import TangemMobileWalletSdk
import BlockchainSdk
import TangemFoundation

/// Utility for creating mock hot wallets for UI testing
/// Creates real hot wallets through MobileWalletSdk to support full transaction signing
enum MockWalletInitializer {
    /// Creates a mock hot wallet with optional mnemonic
    /// - Parameters:
    ///   - mnemonic: Optional mnemonic phrase. If nil, a new wallet will be generated
    ///   - passphrase: Optional passphrase for the wallet
    /// - Returns: UserWalletModel for the created hot wallet
    /// - Throws: Error if wallet creation fails
    static func createMockHotWallet(
        mnemonic: String? = nil,
        passphrase: String? = nil
    ) async throws -> UserWalletModel {
        let initializer = MobileWalletInitializer()

        let mnemonicObject: Mnemonic?
        if let mnemonicString = mnemonic {
            mnemonicObject = try Mnemonic(with: mnemonicString)
        } else {
            mnemonicObject = nil
        }

        let walletInfo = try await initializer.initializeWallet(
            mnemonic: mnemonicObject,
            passphrase: passphrase
        )

        guard let userWalletModel = CommonUserWalletModelFactory().makeModel(
            walletInfo: .mobileWallet(walletInfo),
            keys: .mobileWallet(keys: walletInfo.keys)
        ) else {
            throw MockWalletInitializerError.failedToCreateModel
        }

        return userWalletModel
    }

    /// Creates multiple mock hot wallets for testing
    /// - Parameter count: Number of wallets to create
    /// - Returns: Array of UserWalletModel instances
    /// - Throws: Error if wallet creation fails
    static func createMockHotWallets(count: Int) async throws -> [UserWalletModel] {
        var wallets: [UserWalletModel] = []

        for _ in 0 ..< count {
            let wallet = try await createMockHotWallet()
            wallets.append(wallet)
        }

        return wallets
    }

    /// Creates a mock hot wallet with a specific test mnemonic
    /// Useful for reproducible test scenarios
    /// - Parameter testMnemonic: Test mnemonic phrase (12 or 24 words)
    /// - Returns: UserWalletModel for the created hot wallet
    /// - Throws: Error if wallet creation fails
    static func createMockHotWalletWithTestMnemonic(
        testMnemonic: String
    ) async throws -> UserWalletModel {
        return try await createMockHotWallet(mnemonic: testMnemonic, passphrase: nil)
    }
}

enum MockWalletInitializerError: Error {
    case failedToCreateModel
}
#endif
