//
//  AddressBookManagerError.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum AddressBookManagerError: Error {
    case contactNotFound
    /// The cached book could not be loaded, so mutating it would overwrite the still-intact on-disk blob.
    case bookUnavailable
}
