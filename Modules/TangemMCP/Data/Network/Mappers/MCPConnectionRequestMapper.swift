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
        _ fetchResponse: MCPDeviceVerificationDTO.Get.Response
    ) -> MCPConnectionRequest {
        let agent = MCPAgentMapper.mapToDomain(fetchResponse)

        let scopes = fetchResponse.scope.split(separator: " ").map(String.init)

        return MCPConnectionRequest(
            normalizedUserCode: fetchResponse.userCode,
            oAuthState: fetchResponse.state,
            agent: agent,
            scopes: OrderedSet(scopes)
        )
    }

    static func mapDeviceVerificationPostBody(
        fromDomain domainRequest: MCPConnectionRequest,
        userWalletID: UserWalletId
    ) -> MCPDeviceVerificationDTO.Post.Request.Body {
        MCPDeviceVerificationDTO.Post.Request.Body(
            clientId: domainRequest.agent.id,
            walletId: userWalletID.value.base64EncodedString(),
            scope: domainRequest.scopes.elements
        )
    }

    static func mapDeviceVerificationPostQueryParameters(
        fromDomain domainRequest: MCPConnectionRequest
    ) -> MCPDeviceVerificationDTO.Post.Request.QueryParameters {
        mapDeviceVerificationUserCodeAndStateQueryParameters(fromDomain: domainRequest)
    }

    static func mapDeviceVerificationDeleteQueryParameters(
        fromDomain domainRequest: MCPConnectionRequest
    ) -> MCPDeviceVerificationDTO.Delete.Request.QueryParameters {
        mapDeviceVerificationUserCodeAndStateQueryParameters(fromDomain: domainRequest)
    }

    private static func mapDeviceVerificationUserCodeAndStateQueryParameters(
        fromDomain domainRequest: MCPConnectionRequest
    ) -> MCPDeviceVerificationDTO.UserCodeAndStateQueryParameters {
        MCPDeviceVerificationDTO.UserCodeAndStateQueryParameters(
            userCode: domainRequest.normalizedUserCode,
            state: domainRequest.oAuthState
        )
    }
}
