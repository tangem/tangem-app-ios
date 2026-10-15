//
//  MCPConnectionRequestMapper.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct Foundation.Data
import struct OrderedCollections.OrderedSet
import struct TangemFoundation.UserWalletId

enum MCPConnectionRequestMapper {
    static func mapToDomainRequest(
        _ fetchResponse: FetchMCPConnectionRequestDTO.Response
    ) -> MCPConnectionRequest {
        let agent = MCPConnectionRequest.Agent(
            id: fetchResponse.clientId,
            name: fetchResponse.clientName,
            host: fetchResponse.clientOrigin,
            isVerified: fetchResponse.clientNameVerified
        )

        let scopes = fetchResponse.scope.split(separator: " ").map(String.init)

        return MCPConnectionRequest(
            normalizedUserCode: fetchResponse.userCode,
            oAuthState: fetchResponse.state,
            agent: agent,
            scopes: OrderedSet(scopes)
        )
    }

    static func mapDecisionRequestBody(
        fromDomain domainRequest: MCPConnectionRequest,
        userWalletID: UserWalletId
    ) -> MCPConnectionDecisionDTO.Request.Body {
        MCPConnectionDecisionDTO.Request.Body(
            clientId: domainRequest.agent.id,
            walletId: userWalletID.value.base64EncodedString(),
            scope: domainRequest.scopes.elements
        )
    }

    static func mapDecisionRequestQueryParameters(
        fromDomain domainRequest: MCPConnectionRequest
    ) -> MCPConnectionDecisionDTO.Request.QueryParameters {
        MCPConnectionDecisionDTO.Request.QueryParameters(
            userCode: domainRequest.normalizedUserCode,
            state: domainRequest.oAuthState
        )
    }
}
