//
//  StorageEntry.Version.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

extension StorageEntry {
    enum Version: String, Codable, RawRepresentable {
        case v1
        case v2
        case v3
    }
}
