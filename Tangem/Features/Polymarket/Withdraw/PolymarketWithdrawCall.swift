//
//  PolymarketWithdrawCall.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
import BlockchainSdk
import TangemPolymarket

enum PolymarketWithdrawCall {
    static func transfer(to bridgeAddress: String, amountBaseUnits: BigUInt) throws -> PolymarketRelayedBatch.Call {
        let method = try TransferERC20TokenMethod(destination: bridgeAddress, amount: amountBaseUnits)

        return PolymarketRelayedBatch.Call(
            target: PolymarketCollateral.contractAddress,
            data: method.encodedData
        )
    }

    static func decode(_ call: PolymarketRelayedBatch.Call) -> Transfer? {
        guard call.target.caseInsensitiveCompare(PolymarketCollateral.contractAddress) == .orderedSame,
              let method = TransferERC20TokenMethod(calldata: Data(hexString: call.data)) else {
            return nil
        }

        return Transfer(recipient: method.destination, amountBaseUnits: method.amount)
    }

    static func carries(
        _ call: PolymarketRelayedBatch.Call,
        transferOf amountBaseUnits: BigUInt,
        to bridgeAddress: String
    ) -> Bool {
        guard let decoded = decode(call),
              let expected = try? SmartContractAddress(bridgeAddress.lowercased()) else {
            return false
        }

        return decoded.recipient == expected && decoded.amountBaseUnits == amountBaseUnits
    }

    struct Transfer: Equatable {
        let recipient: SmartContractAddress
        let amountBaseUnits: BigUInt
    }
}
