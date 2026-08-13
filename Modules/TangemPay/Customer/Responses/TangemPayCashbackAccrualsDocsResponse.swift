//
//  TangemPayCashbackAccrualsDocsResponse.swift
//  TangemPay
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct TangemPayCashbackAccrualsDocsResponse: Decodable {
    @DefaultIfMissing
    public var docs: [Doc]
}

// MARK: - Nested Types

public extension TangemPayCashbackAccrualsDocsResponse {
    struct Doc: Codable {
        public let id: String
        public let title: String
        public let url: String
    }
}
