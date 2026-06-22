//
//  AddressBookRepositoryError.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum AddressBookRepositoryError: Error {
    /// The blob's open `version` is newer than this client supports — prompt the user to update.
    case unsupportedBlobVersion(String)
}
