//
//  ExpressHistoryProvider.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct ExpressHistoryProvider: Hashable {
    public let id: String
    public let name: String
    public let iconURL: URL?
    public let providerURL: URL?

    public init(id: String, name: String, iconURL: URL?, providerURL: URL?) {
        self.id = id
        self.name = name
        self.iconURL = iconURL
        self.providerURL = providerURL
    }
}
