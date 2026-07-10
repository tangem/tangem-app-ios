//
//  AddressBookManagerError.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum AddressBookManagerError: LocalizedError {
    case contactNotFound

    var errorDescription: String? {
        switch self {
        case .contactNotFound: "Contact not found"
        }
    }
}
