//
//  AddressBookValidationError.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// User-facing validation failures surfaced by the contact editor and the manager.
enum AddressBookValidationError: Error, Hashable {
    case nameEmpty
    case nameTooLong
    case nameContainsForbiddenCharacters
    case nameNotUnique
    case noEntries
    case tooManyAddresses
    case addressEmpty
    case duplicateAddressNetworkPair
    case addressAlreadySaved(contactName: String)
}
