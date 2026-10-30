//
//  MCPSendIntentMapper.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

enum MCPSendIntentMapper {
    static func mapToDomainIntent(_ response: FetchMCPSendIntentDTO.Response) throws(MCPSendIntentError) -> MCPSendIntent {
        guard response.type.caseInsensitiveCompare("SEND") == .orderedSame else {
            throw .unsupportedType(response.type)
        }

        guard let amount = Decimal(strictStringValue: response.amount), amount > 0 else {
            throw .invalidAmount(response.amount)
        }

        let isCreated = response.status.caseInsensitiveCompare("CREATED") == .orderedSame

        return MCPSendIntent(
            networkId: response.networkId,
            tokenId: response.tokenId,
            fromAddress: response.fromAddress,
            toAddress: response.toAddress,
            amount: amount,
            memo: response.memo,
            isCompleted: !isCreated || response.txHash != nil,
            agentId: response.clientId
        )
    }
}
