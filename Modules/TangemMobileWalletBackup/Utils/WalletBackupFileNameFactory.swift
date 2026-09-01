//
//  WalletBackupFileNameFactory.swift
//  TangemMobileWalletBackup
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

/// Builds the user-visible backup file name: `<wallet name>.backup.json`, or
/// `<wallet name> (N).backup.json` with the smallest free `N` when the name is taken.
struct WalletBackupFileNameFactory {
    private let fileNameSuffix = WalletBackupConstants.fileNameSuffix

    func makeFileName(walletName: String, existingFileNames: [String]) -> String {
        let baseName = sanitizedBaseName(from: walletName)

        // Case-insensitive: iCloud Drive and APFS on macOS treat `Wallet` and `wallet`
        // as the same file, colliding on sync even though iOS distinguishes them locally.
        let takenNames = Set(existingFileNames.map { $0.lowercased() })

        let components = FileNameComponents(baseName: baseName, suffix: fileNameSuffix)
        let resolvedComponents = resolvedComponents(components, takenNames: takenNames)

        return resolvedComponents.fullName
    }
}

// MARK: - Private implementation

private extension WalletBackupFileNameFactory {
    /// Cuts the base name to the byte budget, then numbers the name when it is taken,
    /// and repeats: the ` (N)` insert spends bytes of the same budget, so numbering can
    /// require another cut. Terminates because every pass either returns, strictly
    /// shrinks the base name, or strictly grows the copy number — and `takenNames` is
    /// finite, so a free number is always found.
    func resolvedComponents(_ components: FileNameComponents, takenNames: Set<String>) -> FileNameComponents {
        let truncatedComponents = truncated(components: components)

        guard isNameTaken(components: truncatedComponents, takenNames: takenNames) else {
            return truncatedComponents
        }

        let numberedComponents = numbered(components: truncatedComponents, takenNames: takenNames)
        return resolvedComponents(numberedComponents, takenNames: takenNames)
    }

    func truncated(components: FileNameComponents) -> FileNameComponents {
        let maxUTF8Bytes = maxBaseNameUTF8Bytes(components: components)
        guard needsTruncation(components: components, maxUTF8Bytes: maxUTF8Bytes) else {
            return components
        }

        let truncatedBaseName = truncatedName(components.baseName, maxUTF8Bytes: maxUTF8Bytes)
            .trimmingCharacters(in: Constants.trimmedFileNameEdgeCharacters)

        // A single `Character` can outweigh the whole budget (e.g. Zalgo-style combining
        // marks), leaving nothing after the cut — fall back rather than produce a dot-led
        // hidden file name that iCloud would not sync.
        let baseName = truncatedBaseName.isEmpty ? Constants.fallbackWalletName : truncatedBaseName

        return FileNameComponents(baseName: baseName, suffix: components.suffix, copyNumber: nil)
    }

    func maxBaseNameUTF8Bytes(components: FileNameComponents) -> Int {
        // APFS and iCloud Drive cap a file name at 255 UTF-8 bytes, and exceeding the cap
        // is not a clean error: the local write succeeds, then iCloud renames the synced
        // file keeping only the last extension, so `<name>.backup.json` becomes
        // `<name>.b.json` and stops passing the backup suffix filter.
        let fileSystemNameLimitUTF8Bytes = 255

        // A file not yet downloaded from the cloud is enumerated as a `.<name>.icloud`
        // placeholder, which must fit the same limit.
        let icloudPlaceholderOverheadUTF8Bytes = ".".utf8.count + ".icloud".utf8.count

        // Extra slack for limits beyond APFS: iCloud Drive's server-side rules are
        // undocumented, and the file is also reachable from Windows clients.
        let safetyMarginUTF8Bytes = 7

        return fileSystemNameLimitUTF8Bytes
            - icloudPlaceholderOverheadUTF8Bytes
            - safetyMarginUTF8Bytes
            - components.copyNumberInsert.utf8.count
            - components.suffix.utf8.count
    }

    func needsTruncation(components: FileNameComponents, maxUTF8Bytes: Int) -> Bool {
        components.baseName.utf8.count > maxUTF8Bytes
    }

    func isNameTaken(components: FileNameComponents, takenNames: Set<String>) -> Bool {
        takenNames.contains(components.fullName.lowercased())
    }

    /// Smallest copy number making the name free; numbering starts at 1.
    func numbered(components: FileNameComponents, takenNames: Set<String>) -> FileNameComponents {
        var numberedComponents = components

        while isNameTaken(components: numberedComponents, takenNames: takenNames) {
            numberedComponents.incrementCopyNumber()
        }

        return numberedComponents
    }

    func sanitizedBaseName(from walletName: String) -> String {
        let name = walletName
            .components(separatedBy: Constants.forbiddenFileNameCharacters)
            .joined()
            .trimmingCharacters(in: Constants.trimmedFileNameEdgeCharacters)

        return name.isEmpty ? Constants.fallbackWalletName : name
    }

    /// Longest prefix of `name` that fits into `maxUTF8Bytes` of UTF-8 without splitting
    /// a `Character`, so multi-byte letters and emoji survive the cut intact.
    func truncatedName(_ name: String, maxUTF8Bytes: Int) -> String {
        var byteCount = 0

        for index in name.indices {
            byteCount += name[index].utf8.count

            if byteCount > maxUTF8Bytes {
                return String(name[..<index])
            }
        }

        return name
    }
}

// MARK: - FileNameComponents

private extension WalletBackupFileNameFactory {
    struct FileNameComponents {
        let baseName: String
        let suffix: String
        var copyNumber: Int?

        /// ` (N)` insert between the base name and the suffix, empty without a number.
        var copyNumberInsert: String {
            copyNumber.map { " (\($0))" } ?? .empty
        }

        var fullName: String {
            baseName + copyNumberInsert + suffix
        }

        mutating func incrementCopyNumber() {
            copyNumber = copyNumber.map { $0 + 1 } ?? Constants.firstFileCopyNumber
        }
    }
}

// MARK: - Constants

private extension WalletBackupFileNameFactory {
    enum Constants {
        static let fallbackWalletName = "Wallet"
        static let firstFileCopyNumber: Int = 1

        /// Characters invalid on at least one file system the backup file can reach:
        /// `/` on APFS, `:` in the Finder (HFS legacy), `\ / : * ? " < > |` in iCloud
        /// for Windows, plus `%` to avoid URL-encoding surprises. Removed anywhere in the name.
        static let forbiddenFileNameCharacters = CharacterSet(charactersIn: "/\\:?%*|\"<>")

        /// Stripped from the edges of the name only: a leading dot would make the file
        /// hidden and not synced by iCloud Drive, trailing dots and whitespace are
        /// invalid on Windows. Both are legal in the middle of the name.
        static let trimmedFileNameEdgeCharacters = CharacterSet.whitespacesAndNewlines
            .union(CharacterSet(charactersIn: "."))
    }
}
