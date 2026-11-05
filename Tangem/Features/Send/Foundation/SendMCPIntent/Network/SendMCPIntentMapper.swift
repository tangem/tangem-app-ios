//
//  SendMCPIntentMapper.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

enum SendMCPIntentMapper {
    static func mapToDomainIntent(_ response: FetchMCPSendIntentDTO.Response) throws(SendMCPIntentError) -> SendMCPIntent {
        guard response.type.caseInsensitiveCompare("SEND") == .orderedSame else {
            throw .unsupportedType(response.type)
        }

        guard let amount = Decimal(strictStringValue: response.amount), amount > 0 else {
            throw .invalidAmount(response.amount)
        }

        let isCreated = response.status.caseInsensitiveCompare("CREATED") == .orderedSame

        return SendMCPIntent(
            id: response.intentId,
            networkID: response.networkId,
            tokenID: response.tokenId,
            fromAddress: response.fromAddress,
            toAddress: response.toAddress,
            amount: amount,
            memo: response.memo,
            isCompleted: !isCreated || response.txHash != nil,
            agentID: response.clientId
        )
    }
}
