//
//  FetchMCPConnectionRequestDTO.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

/// `GET /api/authentication/v1/mcp/device_verification`
enum FetchMCPConnectionRequestDTO {
    enum Request {
        struct QueryParameters {
            let userCode: String

            var asURLParameters: [String: Any] {
                ["user_code": userCode]
            }
        }
    }

    struct Response: Decodable {
        let clientId: String
        let clientOrigin: String?
        let clientName: String?
        let clientNameVerified: Bool
        let state: String
        let userCode: String
        let scope: String
    }
}
