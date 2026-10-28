//
//  FetchMCPAgentDTO.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct Foundation.URL

/// `GET api/authentication/v1/mcp/client`
enum FetchMCPAgentDTO {
    struct Response: Decodable {
        let clientId: String
        let clientOrigin: String?
        let clientName: String?
        let clientIconUrl: URL?
    }
}
