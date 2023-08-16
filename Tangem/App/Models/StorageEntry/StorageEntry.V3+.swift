//
//  StorageEntry.V3+.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

extension StorageEntry.V3.Entry {
    var isCustom: Bool { id == nil }

    var isToken: Bool { contractAddress != nil }
}
