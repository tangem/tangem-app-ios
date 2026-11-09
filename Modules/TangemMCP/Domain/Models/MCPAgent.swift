//
//  MCPAgent.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public import struct Foundation.URL

/// AI agent such as Claude or Codex acting on the wallet owner's behalf.
public struct MCPAgent: Equatable, Sendable {
    /// Opaque OAuth `client_id` identifying the agent.
    public let id: String

    /// The agent's display name.
    public let name: String

    /// Domain the agent's registration was fetched from and confirmed by the server.
    public let host: String

    /// The agent's icon.
    public let icon: URL?

    init(id: String, name: String?, host: String?, icon: URL?) {
        self.id = id
        self.name = name ?? Self.fallbackName
        self.host = host ?? Self.fallbackHost
        self.icon = icon
    }
}

extension MCPAgent {
    private static let fallbackName = "AI Agent"
    private static let fallbackHost = "mcp.tangem.org"
}
