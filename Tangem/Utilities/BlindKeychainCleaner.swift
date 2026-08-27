//
//  BlindKeychainCleaner.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Security
import TangemSdk
import TangemFoundation

/// Deletes Keychain items by class instead of by name, covering what the enumeration in `KeychainCleaner`
/// can't hand to its owners: items behind a biometric ACL are skipped there, and their names can't be
/// reconstructed — the wallet-id lists they are built from don't survive a reinstall. `SecItemDelete`
/// evaluates no ACL and shows no UI, so it reaches them without authentication.
///
/// The queries carry no predicate beyond the class: anything narrower could fail to match and leave a
/// secret behind. The one item that has to survive a reinstall — the payload of an interrupted card
/// backup — is a generic password like the rest, so it is read out first and stored back afterwards.
struct BlindKeychainCleaner {
    private let secureStorage = SecureStorage()

    func clean() {
        delete(itemClass: kSecClassKey)

        let backupData = existingBackupData()
        delete(itemClass: kSecClassGenericPassword)
        writeBackupData(backupData)
    }

    private func existingBackupData() -> Data? {
        do {
            return try secureStorage.get(Constants.backupDataAccount)
        } catch {
            // The wipe runs regardless: leftovers skipped here are never revisited, since the cleanup
            // only ever runs on the first launch.
            AppLogger.error("The card backup payload is unreadable, it goes with the wipe", error: error)
            return nil
        }
    }

    private func writeBackupData(_ data: Data?) {
        guard let backupData = data else {
            return
        }

        do {
            try secureStorage.store(backupData, forKey: Constants.backupDataAccount)
        } catch {
            AppLogger.error("Failed to restore the card backup payload", error: error)
        }
    }

    private func delete(itemClass: CFString) {
        let query: [String: Any] = [kSecClass as String: itemClass]
        let status = SecItemDelete(query as CFDictionary)

        if status != errSecSuccess, status != errSecItemNotFound {
            AppLogger.error(error: "Failed to wipe \(itemClass) from the Keychain: OSStatus \(status)")
        }
    }
}

private extension BlindKeychainCleaner {
    enum Constants {
        /// Mirrors `SecureStorageKey.backupData`, which TangemSdk keeps internal.
        static let backupDataAccount = "backupData"
    }
}
