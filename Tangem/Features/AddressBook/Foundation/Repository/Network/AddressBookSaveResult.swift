//
//  AddressBookSaveResult.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct AddressBookSaveResult: Hashable {
    let etag: String
    let updatedAt: Date
}
