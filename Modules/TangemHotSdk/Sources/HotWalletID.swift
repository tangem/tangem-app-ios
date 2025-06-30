//
//  HotWalletId.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public struct HotWalletID: Equatable, Hashable, Codable {
    public let value: String
    public let authType: AuthType?

    public init(value: String, authType: AuthType?) {
        self.value = value
        self.authType = authType
    }

    init(authType: AuthType?) {
        value = UUID().uuidString
        self.authType = authType
    }

    public enum AuthType: String, Codable, CaseIterable {
        case biometrics
        case password
    }
}
