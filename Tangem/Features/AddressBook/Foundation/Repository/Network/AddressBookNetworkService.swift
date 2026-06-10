//
//  AddressBookNetworkService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol AddressBookNetworkService {
    func getAddressBook(retryCount: Int) async throws -> AddressBook
    func saveAddressBook(_ addressBook: AddressBook, retryCount: Int) async throws
}

enum AddressBookSynchronisationState: Hashable {
    case idle
    case syncing
    case synced
}
