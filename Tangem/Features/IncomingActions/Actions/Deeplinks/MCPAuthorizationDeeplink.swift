//
//  MCPAuthorizationDeeplink.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// `tangem://mcp.authorization?user_code`
///
/// The MCP pairing link the backend's device-authorization page renders — as a QR for a second device to
/// scan, or, tapped directly, for when the agent and the wallet are paired from the same device, which can't
/// scan its own screen. The user code names nothing on its own: without it there is nothing to approve.
struct MCPAuthorizationDeeplink: HostNamedDeeplink, Equatable {
    static let host = "mcp.authorization"

    let userCode: String

    var action: DeeplinkNavigationAction { .mcpAuthorization(self) }
}

// MARK: - Parsing

extension MCPAuthorizationDeeplink {
    private enum Keys {
        static let userCode = "user_code"
    }

    init(link: DeeplinkURL) throws {
        userCode = try link.query.required(Keys.userCode)
    }
}
