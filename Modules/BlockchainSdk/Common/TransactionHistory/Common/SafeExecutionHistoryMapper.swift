//
//  SafeExecutionHistoryMapper.swift
//  BlockchainSdk
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

enum SafeExecutionHistoryMapper {
    struct Execution {
        let type: TransactionRecord.TransactionType
        let destination: TransactionRecord.Destination.Address
        let amount: Decimal
        let fee: Fee
        let tokenTransfers: [TransactionRecord.TokenTransfer]
    }

    static func execution(
        calldata: String?,
        target: String?,
        walletAddress: String,
        blockchain: Blockchain
    ) -> Execution? {
        guard
            let calldata,
            let target,
            target.caseInsensitiveEquals(to: walletAddress),
            let method = SafeExecTransactionMethod(calldata: calldata),
            method.operation == .call,
            method.gasToken.caseInsensitiveEquals(to: SafeGasToken.coinGasTokenRawValue),
            let value = method.innerCall.value.decimal,
            let refundCap = method.refundCap.decimal
        else {
            return nil
        }

        let amount = value / blockchain.decimalValue
        let fee = Fee(Amount(with: blockchain, value: refundCap / blockchain.decimalValue))

        switch try? SafeInnerCallTypeParser.parse(method.innerCall) {
        case .transfer(.coin(let destination, _)):
            return Execution(type: .transfer, destination: .user(destination), amount: amount, fee: fee, tokenTransfers: [])
        case .transfer(.token(let contractAddress, let destination, let tokenValue)):
            let tokenTransfers = tokenValue.decimal.map { tokenAmount in
                [TransactionRecord.TokenTransfer(
                    source: walletAddress,
                    destination: destination,
                    amount: tokenAmount,
                    name: nil,
                    symbol: nil,
                    decimals: nil,
                    contract: contractAddress
                )]
            }

            return Execution(type: .transfer, destination: .contract(contractAddress), amount: amount, fee: fee, tokenTransfers: tokenTransfers ?? [])
        case nil:
            return Execution(type: .unknownOperation, destination: .contract(method.innerCall.to), amount: amount, fee: fee, tokenTransfers: [])
        }
    }
}
