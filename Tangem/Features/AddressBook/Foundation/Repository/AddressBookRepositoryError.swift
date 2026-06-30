//
//  AddressBookRepositoryError.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum AddressBookRepositoryError: LocalizedError {
    case unsupportedBlobVersion(String)
    case bookUnavailable

    var errorDescription: String? {
        switch self {
        case .unsupportedBlobVersion: "Address book version is not supported"
        case .bookUnavailable: "Book unavailable"
        }
    }
}
