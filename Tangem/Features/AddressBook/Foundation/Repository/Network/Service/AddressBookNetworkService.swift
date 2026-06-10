//
//  AddressBookNetworkService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol AddressBookNetworkService {
    @discardableResult
    func getAddressBook(
        retryCount: Int
    ) async throws(AddressBookNetworkServiceError) -> RemoteAddressBookInfo

    @discardableResult
    func saveAddressBook(
        _ addressBook: AddressBook,
        version: String?,
        retryCount: Int
    ) async throws(AddressBookNetworkServiceError) -> RemoteAddressBookInfo
}
