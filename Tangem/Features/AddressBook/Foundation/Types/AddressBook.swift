//
//  AddressBook.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct AddressBook: Equatable {
    let userWalletId: UserWalletId
    let contacts: [AddressBookContact]
}

// MARK: - Codable

extension AddressBook: Codable {
    enum CodingKeys: String, CodingKey {
        case userWalletId
        case contacts
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let userWalletIdValue = try container.decode(Data.self, forKey: .userWalletId)
        userWalletId = UserWalletId(value: userWalletIdValue)
        contacts = try container.decode([AddressBookContact].self, forKey: .contacts)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(userWalletId.value, forKey: .userWalletId)
        try container.encode(contacts, forKey: .contacts)
    }
}
