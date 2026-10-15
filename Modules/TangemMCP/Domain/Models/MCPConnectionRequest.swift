//
//  MCPConnectionRequest.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct OrderedCollections.OrderedSet

/// Pending MCP agent connection request, fetched by user code, before the wallet owner accepts or rejects it.
struct MCPConnectionRequest: Equatable, Sendable {
    /// Canonical form of the user code, as normalized by the server.
    let normalizedUserCode: String

    /// Opaque [RFC 6749 OAuth 2.0 state](https://www.rfc-editor.org/rfc/rfc6749.html#section-4.1.1).
    /// - Note: Sent back unmodified when submitting Accept/Reject.
    let oAuthState: String

    /// The agent requesting the connection.
    let agent: Agent

    // [REDACTED_TODO_COMMENT]
    /// Permissions the agent is requesting, e.g. "tokens:read".
    let scopes: OrderedSet<String>
}

extension MCPConnectionRequest {
    /// The MCP agent requesting the connection.
    struct Agent: Equatable, Sendable {
        /// Opaque OAuth client_id.
        let id: String

        /// The agent display name.
        let name: String?

        /// Domain the agent's registration was fetched from and confirmed by the server.
        /// - Remark: `nil` when ``isVerified`` is `true`.
        let host: String?

        /// Indicates whether the agent is among Tangem's own server-side pre-registered list.
        let isVerified: Bool
    }
}
