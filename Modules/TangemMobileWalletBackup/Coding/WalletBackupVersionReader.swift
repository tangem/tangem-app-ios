//
//  WalletBackupVersionReader.swift
//  TangemMobileWalletBackup
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Reads only the `version` field of a backup file.
enum WalletBackupVersionReader {
    static func version(in fileData: Data) -> Int? {
        try? WalletBackupJSONCodec.decode(FileVersion.self, from: fileData).version
    }

    private struct FileVersion: Decodable {
        let version: Int
    }
}
