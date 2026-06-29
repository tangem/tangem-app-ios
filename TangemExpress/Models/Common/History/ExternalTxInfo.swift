//
//  ExternalTxInfo.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct ExternalTxInfo: Hashable {
    public let id: String
    public let url: URL?

    public init(
        id: String,
        url: URL?
    ) {
        self.id = id
        self.url = url
    }
}
