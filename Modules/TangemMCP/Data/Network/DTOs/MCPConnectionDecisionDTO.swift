//
//  MCPConnectionDecisionDTO.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

/// `POST /api/authentication/v1/mcp/device_verification`
enum MCPConnectionDecisionDTO {
    enum Request {
        struct QueryParameters {
            let userCode: String
            let state: String

            var asURLParameters: [String: Any] {
                ["user_code": userCode, "state": state]
            }
        }

        struct Body: Encodable {
            let clientId: String
            let walletId: String
            let scope: [String]
        }
    }

    struct Response: Decodable {
        let success: Bool
    }
}
