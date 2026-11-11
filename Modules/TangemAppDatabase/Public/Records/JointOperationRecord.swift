//
//  JointOperationRecord.swift
//  TangemAppDatabase
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import GRDB

public struct JointOperationRecord {
    public let id: String
    public let cryptoAccountID: String
    public let safeAddress: String
    public let chainID: Int
    public let status: String
    public let initiator: String
    public let to: String
    public let value: String
    public let data: String
    public let operation: Int
    public let safeTxGas: String
    public let baseGas: String
    public let gasPrice: String
    public let gasToken: String
    public let refundReceiver: String
    public let nonce: Int
    public let threshold: Int
    public let txHash: String?
    public let cancelReason: String?
    public let signatures: [Signature]
    public let createdAt: Date
    public let finishedAt: Date?

    public init(
        id: String,
        cryptoAccountID: String,
        safeAddress: String,
        chainID: Int,
        status: String,
        initiator: String,
        to: String,
        value: String,
        data: String,
        operation: Int,
        safeTxGas: String,
        baseGas: String,
        gasPrice: String,
        gasToken: String,
        refundReceiver: String,
        nonce: Int,
        threshold: Int,
        txHash: String?,
        cancelReason: String?,
        signatures: [Signature],
        createdAt: Date,
        finishedAt: Date?
    ) {
        self.id = id
        self.cryptoAccountID = cryptoAccountID
        self.safeAddress = safeAddress
        self.chainID = chainID
        self.status = status
        self.initiator = initiator
        self.to = to
        self.value = value
        self.data = data
        self.operation = operation
        self.safeTxGas = safeTxGas
        self.baseGas = baseGas
        self.gasPrice = gasPrice
        self.gasToken = gasToken
        self.refundReceiver = refundReceiver
        self.nonce = nonce
        self.threshold = threshold
        self.txHash = txHash
        self.cancelReason = cancelReason
        self.signatures = signatures
        self.createdAt = createdAt
        self.finishedAt = finishedAt
    }
}

// MARK: - Auxiliary types

public extension JointOperationRecord {
    struct Signature: Codable, Equatable {
        public let address: String
        public let state: String
        public let at: String

        public init(address: String, state: String, at: String) {
            self.address = address
            self.state = state
            self.at = at
        }
    }
}

// MARK: - Identifiable protocol conformance

extension JointOperationRecord: Identifiable {}

// MARK: - Codable protocol conformance

extension JointOperationRecord: Codable {}

// MARK: - FetchableRecord protocol conformance

extension JointOperationRecord: FetchableRecord {}

// MARK: - TableRecord protocol conformance

extension JointOperationRecord: TableRecord {
    public enum Columns {
        public static let id = Column(CodingKeys.id)
        public static let safeAddress = Column(CodingKeys.safeAddress)
        public static let finishedAt = Column(CodingKeys.finishedAt)
    }

    public static let databaseTableName = JointOperationsTable.tableName
}

// MARK: - PersistableRecord protocol conformance

extension JointOperationRecord: PersistableRecord {}
