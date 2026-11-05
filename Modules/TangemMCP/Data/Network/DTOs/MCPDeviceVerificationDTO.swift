//
//  MCPDeviceVerificationDTO.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct Foundation.URL

/// `api/authentication/v1/mcp/device_verification`
enum MCPDeviceVerificationDTO {
    struct UserCodeAndStateQueryParameters {
        let userCode: String
        let state: String

        var asURLParameters: [String: Any] {
            ["user_code": userCode, "state": state]
        }
    }
}

// MARK: - GET

extension MCPDeviceVerificationDTO {
    enum Get {
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
            let clientIconUrl: URL?
            let state: String
            let userCode: String
            let scope: String
        }
    }
}

// MARK: - POST

extension MCPDeviceVerificationDTO {
    enum Post {
        enum Request {
            typealias QueryParameters = UserCodeAndStateQueryParameters

            struct Body: Encodable {
                let clientId: String
                let walletId: String
                let scope: [String]
            }
        }
    }
}

// MARK: - DELETE

extension MCPDeviceVerificationDTO {
    enum Delete {
        enum Request {
            typealias QueryParameters = UserCodeAndStateQueryParameters
        }
    }
}
