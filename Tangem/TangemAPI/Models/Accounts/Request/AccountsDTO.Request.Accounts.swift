//
//  AccountsDTO.Request.Accounts.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension AccountsDTO.Request {
    struct Accounts: Encodable {
        struct Account {
            let id: String
            /// Nil, if the account uses a localized name.
            let name: String?
            let icon: String
            let iconColor: String
            let derivation: Int
        }

        let accounts: [Account]
    }
}

// MARK: - Encodable protocol conformance

extension AccountsDTO.Request.Accounts.Account: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        // This API requires sending `null` value for accounts with localized names, the absence of the `name` field is not accepted
        if let name {
            try container.encode(name, forKey: .name)
        } else {
            try container.encodeNil(forKey: .name)
        }

        try container.encode(id, forKey: .id)
        try container.encode(icon, forKey: .icon)
        try container.encode(iconColor, forKey: .iconColor)
        try container.encode(derivation, forKey: .derivation)
    }
}

// MARK: - Auxiliary types

private extension AccountsDTO.Request.Accounts.Account {
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case icon
        case iconColor
        case derivation
    }
}
