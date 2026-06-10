//
//  CommonAddressBookNetworkService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemFoundation

struct CommonAddressBookNetworkService {
    private let userWalletId: UserWalletId

    init(userWalletId: UserWalletId) {
        self.userWalletId = userWalletId
    }
}

// MARK: - AddressBookNetworkService

extension CommonAddressBookNetworkService: AddressBookNetworkService {
    func getAddressBook(retryCount: Int) async throws -> AddressBook {
        // [REDACTED_TODO_COMMENT]
        // AddressBookDTO.Save.Response
        throw CommonError.notImplemented
    }
    
    func saveAddressBook(_ addressBook: AddressBook, retryCount: Int) async throws {
        // [REDACTED_TODO_COMMENT]
        // AddressBookDTO.Save.Response
        throw CommonError.notImplemented
    }
}
