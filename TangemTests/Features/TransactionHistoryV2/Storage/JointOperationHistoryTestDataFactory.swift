//
//  JointOperationHistoryTestDataFactory.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
@testable import Tangem
@testable import BlockchainSdk

enum JointOperationHistoryTestDataFactory {
    static let baseChainId = 8453
    static let unsupportedChainId = 324
    static let safeAddress = "0x8f3ac21b7e5f4552091a69125d5dfcb7b8c26590"
    static let checksummedTokenContract = "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913"
    static let recipient = "0x2b5ad5c4795c026514f8317c7a215e218dccd6cf"
    static let initiator = "0x7e5f4552091a69125d5dfcb7b8c2659029395bdf"
    static let createdAt = Date(timeIntervalSince1970: 1_757_323_237)
    static let finishedAt = Date(timeIntervalSince1970: 1_757_323_442)

    static func coinItem(
        id: String = "operation-1",
        status: JointAccountOperationStatus = .executed,
        chainId: Int = baseChainId
    ) -> JointOperationHistoryItem {
        item(id: id, status: status, chainId: chainId, safeTransaction: coinSafeTransaction())
    }

    static func tokenItem(id: String = "operation-1", status: JointAccountOperationStatus = .executed) throws -> JointOperationHistoryItem {
        item(id: id, status: status, chainId: baseChainId, safeTransaction: try tokenSafeTransaction())
    }

    static func delegateCallItem(id: String = "operation-1") -> JointOperationHistoryItem {
        item(id: id, status: .executed, chainId: baseChainId, safeTransaction: coinSafeTransaction(operation: 1))
    }

    static func coinInfo(id: String, status: JointAccountOperationStatus) -> JointOperationHistoryInfo {
        JointOperationHistoryInfo(
            item: coinItem(id: id, status: status),
            innerCallType: .transfer(.coin(destination: recipient, value: BigUInt(10).power(18)))
        )
    }

    static func info(_ item: JointOperationHistoryItem) throws -> JointOperationHistoryInfo {
        JointOperationHistoryInfo(
            item: item,
            innerCallType: try SafeInnerCallTypeParser.parse(item.operation.safeTransaction.innerCall)
        )
    }

    static func item(
        id: String,
        status: JointAccountOperationStatus,
        chainId: Int,
        safeTransaction: SafeTransaction
    ) -> JointOperationHistoryItem {
        let isFinished = !status.isInFlight

        let operation = JointAccountOperation(
            id: id,
            chainId: chainId,
            safeTransaction: safeTransaction,
            status: status,
            txHash: status == .executed ? "0x4e3a3754410177e6937ef1f84bba68ea139e8d1a2258c5f85db9f1cd715a1bdd" : nil,
            finishedAt: isFinished ? finishedAt : nil,
            cancelReason: status == .cancelled ? .threshold : nil,
            initiator: initiator,
            signatures: [
                JointAccountOperation.Signature(address: initiator, state: .signed, at: "2026-09-08T09:20:37.000Z"),
                JointAccountOperation.Signature(address: recipient, state: .declined, at: "2026-09-08T09:23:51.000Z"),
            ],
            createdAt: createdAt,
            threshold: 2
        )

        return JointOperationHistoryItem(
            operation: operation,
            cryptoAccountId: "crypto-account-1",
            safeAddress: safeAddress,
            createdAt: createdAt,
            threshold: 2
        )
    }

    static func coinSafeTransaction(operation: Int = 0) -> SafeTransaction {
        SafeTransaction(
            to: recipient,
            value: BigUInt(10).power(18),
            data: Data(),
            operation: operation,
            safeTxGas: 65_000,
            baseGas: 30_000,
            gasPrice: 2_000_000_000,
            gasToken: "0x0000000000000000000000000000000000000000",
            refundReceiver: initiator,
            nonce: 7
        )
    }

    static func tokenSafeTransaction() throws -> SafeTransaction {
        SafeTransaction(
            to: checksummedTokenContract,
            value: 0,
            data: try TransferERC20TokenMethod(destination: recipient, amount: 5_000_000).data,
            operation: 0,
            safeTxGas: 65_000,
            baseGas: 30_000,
            gasPrice: 2_000_000_000,
            gasToken: "0x0000000000000000000000000000000000000000",
            refundReceiver: initiator,
            nonce: 8
        )
    }
}
