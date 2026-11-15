//
//  MCPAgentMapper.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

enum MCPAgentMapper {
    static func mapToDomain(_ clientResponse: MCPClientDTO.Get.Response) -> MCPAgent {
        MCPAgent(
            id: clientResponse.clientId,
            name: clientResponse.clientName,
            host: clientResponse.clientOrigin,
            icon: clientResponse.clientIconUrl
        )
    }

    static func mapToDomain(_ deviceVerificationResponse: MCPDeviceVerificationDTO.Get.Response) -> MCPAgent {
        MCPAgent(
            id: deviceVerificationResponse.clientId,
            name: deviceVerificationResponse.clientName,
            host: deviceVerificationResponse.clientOrigin,
            icon: deviceVerificationResponse.clientIconUrl
        )
    }

    static func mapToDomain(_ sessionResponse: MCPSessionsDTO.Get.Session) -> MCPAgent {
        MCPAgent(
            id: sessionResponse.clientId,
            name: sessionResponse.clientName,
            host: sessionResponse.clientOrigin,
            icon: sessionResponse.clientIconUrl
        )
    }
}
