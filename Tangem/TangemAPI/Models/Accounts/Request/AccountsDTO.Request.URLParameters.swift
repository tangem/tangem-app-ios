//
//  AccountsDTO.Request.URLParameters.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension AccountsDTO.Request {
    struct URLParameters {
        let supportedAccountTypes: [AccountType]
    }
}

// MARK: - Encodable protocol conformance

extension AccountsDTO.Request.URLParameters: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        let types = supportedAccountTypes.map(\.rawValue).joined(separator: ",")
        try container.encode(types, forKey: .supportedAccountTypes)
    }
}

// MARK: - Auxiliary types

private extension AccountsDTO.Request.URLParameters {
    enum CodingKeys: String, CodingKey {
        case supportedAccountTypes
    }
}
