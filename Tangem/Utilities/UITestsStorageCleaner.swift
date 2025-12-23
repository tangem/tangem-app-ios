//
//  UITestsStorageCleaner.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

/// Utility class for cleaning storage files during UI tests
enum UITestsStorageCleaner {
    /// Clears all cached files for UI tests
    static func clearCachedFiles() {
        #if DEBUG
        AppLogger.info("Clearing cached files for UI tests")

        let fileManager = FileManager.default
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]

        let cacheFiles = [
            "cached_balances.json",
            "cached_quotes.json",
            "cached_express_availability.json",
        ]

        for cacheFile in cacheFiles {
            let fileURL = cachesDirectory.appendingPathComponent(cacheFile)
            if fileManager.fileExists(atPath: fileURL.path) {
                do {
                    try fileManager.removeItem(at: fileURL)
                    AppLogger.info("Cleared cache file: \(cacheFile)")
                } catch {
                    AppLogger.error(error: "Failed to clear cache file \(cacheFile): \(error)")
                }
            }
        }

        AppLogger.info("Cached files cleared for UI tests")
        #endif
    }

    /// Clears all wallet data including Documents/user_wallets and Keychain
    static func clearWalletData() {
        #if DEBUG
        AppLogger.info("Clearing wallet data for UI tests")

        /// Clear Documents/user_wallets directory
        let userWalletDataStorage = UserWalletDataStorage()
        userWalletDataStorage.clear()

        // Clear WalletConnect encrypted files
        clearWalletConnectFiles()

        // Clear all Keychain data (including encryption keys stored in BiometricsStorage)
        KeychainCleaner.cleanAllData()

        AppLogger.info("Wallet data cleared for UI tests")
        #endif
    }

    /// Clears WalletConnect encrypted files from Documents directory
    private static func clearWalletConnectFiles() {
        #if DEBUG
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]

        /// WalletConnect files that are encrypted and stored in Documents directory
        let walletConnectFiles = [
            "wallet_connect_sessions.json", // New format
            "wc_sessions.json", // Old format
        ]

        for fileName in walletConnectFiles {
            let fileURL = documentsDirectory.appendingPathComponent(fileName)
            if fileManager.fileExists(atPath: fileURL.path) {
                do {
                    try fileManager.removeItem(at: fileURL)
                    AppLogger.info("Cleared WalletConnect file: \(fileName)")
                } catch {
                    AppLogger.error(error: "Failed to clear WalletConnect file \(fileName): \(error)")
                }
            }
        }
        #endif
    }
}
