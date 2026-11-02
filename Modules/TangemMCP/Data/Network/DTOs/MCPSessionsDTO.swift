//
//  MCPSessionsDTO.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct Foundation.Date
import struct Foundation.URL

/// `api/authentication/v1/mcp/sessions`
enum MCPSessionsDTO {}

// MARK: - GET

extension MCPSessionsDTO {
    enum Get {
        typealias Response = [Session]

        struct Session: Decodable {
            let id: String
            let walletId: String
            let clientId: String
            let clientOrigin: String?
            let clientName: String?
            let clientIconUrl: URL?

            /// - Important: ISO-8601
            let createdAt: Date
        }
    }
}

// MARK: - DELETE

extension MCPSessionsDTO {
    enum Delete {
        enum Request {
            struct QueryParameters {
                let walletID: String

                var asURLParameters: [String: Any] {
                    ["walletId": walletID]
                }
            }
        }
    }
}
