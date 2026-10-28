//
//  MCPAgentMapper.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

enum MCPAgentMapper {
    static func mapToDomain(_ fetchResponse: FetchMCPAgentDTO.Response) -> MCPAgent {
        MCPAgent(
            id: fetchResponse.clientId,
            name: fetchResponse.clientName,
            host: fetchResponse.clientOrigin,
            icon: fetchResponse.clientIconUrl
        )
    }

    static func mapToDomain(_ fetchResponse: FetchMCPConnectionRequestDTO.Response) -> MCPAgent {
        MCPAgent(
            id: fetchResponse.clientId,
            name: fetchResponse.clientName,
            host: fetchResponse.clientOrigin,
            icon: fetchResponse.clientIconUrl
        )
    }
}
