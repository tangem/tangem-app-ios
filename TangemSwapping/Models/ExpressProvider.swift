//
//  ExpressProvider.swift
//  TangemSwapping
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public struct ExpressProvider: Hashable {
    public let id: String
    public let name: String
    public let url: URL
    public let type: ProviderType

    public init(id: String, name: String, url: URL, type: ExpressProvider.ProviderType) {
        self.id = id
        self.name = name
        self.url = url
        self.type = type
    }
}

public extension ExpressProvider {
    enum ProviderType: String, Hashable {
        case dex
        case cex
    }
}
