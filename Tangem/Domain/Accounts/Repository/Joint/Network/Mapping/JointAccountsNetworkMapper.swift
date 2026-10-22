//
//  JointAccountsNetworkMapper.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import BigInt
import TangemFoundation

struct JointAccountsNetworkMapper {}

// MARK: - Requests

extension JointAccountsNetworkMapper {
    func mapToRequest<Payload: Encodable>(from blob: JointAccountSignedBlob<Payload>) -> JointAccountsDTO.Request.SignedRequest<Payload> {
        JointAccountsDTO.Request.SignedRequest(
            payload: blob.payload,
            signature: blob.signature.hexString.addHexPrefix()
        )
    }

    func mapToRequest(from request: JointAccountOperationRequest) throws -> JointAccountsDTO.Request.CreateOperation {
        try JointAccountsDTO.Request.CreateOperation(
            safeAddress: request.safeAddress,
            chainId: request.chainId,
            safeTx: mapToSafeTx(from: request.safeTransaction),
            signature: request.signature.hexString.addHexPrefix()
        )
    }

    func mapToRequest(safeTransaction: SafeTransaction, signature: Data) throws -> JointAccountsDTO.Request.SignOperation {
        try JointAccountsDTO.Request.SignOperation(
            safeTx: mapToSafeTx(from: safeTransaction),
            signature: signature.hexString.addHexPrefix()
        )
    }

    /// The transaction worded as the contract speaks it: `uint256` values as decimal strings, the calldata as lowercase
    /// hex. Creating an operation and signing one both send it, and the endpoint checks the second against the first,
    /// so the wording lives here and nowhere else.
    func mapToSafeTx(from safeTransaction: SafeTransaction) throws -> JointAccountsDTO.SafeTx {
        try JointAccountsDTO.SafeTx(
            to: safeTransaction.to,
            value: safeTransaction.value.description,
            data: safeTransaction.data.hexString.lowercased().addHexPrefix(),
            operation: operation(safeTransaction.operation),
            safeTxGas: safeTransaction.safeTxGas.description,
            baseGas: safeTransaction.baseGas.description,
            gasPrice: safeTransaction.gasPrice.description,
            gasToken: safeTransaction.gasToken,
            refundReceiver: safeTransaction.refundReceiver,
            nonce: String(safeTransaction.nonce)
        )
    }
}

// MARK: - Responses

extension JointAccountsNetworkMapper {
    func mapToCreationResult(from response: JointAccountsDTO.Response.JointAccount) throws -> JointAccountCreationResult {
        let invites = (response.invites ?? []).map { StoredJointAccountInvite(id: $0.id) }
        let freeSlotsCount = max(0, response.membersCount - response.members.count)

        if invites.count != freeSlotsCount {
            // Neither reissued nor readable afterwards, so a slot that came back without an invite can never be
            // filled — worth seeing in the logs of a wallet whose creator turns out unable to invite anybody
            JointAccountsLogger.warning("A joint account was created with \(invites.count) invites for \(freeSlotsCount) free slots")
        }

        return try JointAccountCreationResult(account: mapToJointAccount(from: response), invites: invites)
    }

    func mapToJointAccounts(from response: JointAccountsDTO.Response.JointAccounts) throws -> [RemoteJointAccount] {
        try response.jointAccounts.map(mapToJointAccount(from:))
    }

    func mapToJointAccount(from dto: JointAccountsDTO.Response.JointAccount) throws -> RemoteJointAccount {
        let members = dto.members.map { member in
            StoredJointAccount.Member(name: member.name, address: member.address, role: member.role, inviteId: member.inviteId)
        }

        let status = try mapStatus(from: dto)
        let operations = try dto.operations?.map(mapToOperation(from:)) ?? []

        return RemoteJointAccount(
            cryptoAccountId: dto.cryptoAccountId,
            membersCount: dto.membersCount,
            threshold: dto.threshold,
            status: status,
            members: members,
            operations: operations
        )
    }

    func mapToInvitePreview(from response: JointAccountsDTO.Response.InvitePreview) -> JointAccountInvitePreview {
        JointAccountInvitePreview(
            config: response.config,
            creator: JointAccountInvitePreview.Creator(name: response.creator.name, address: response.creator.address)
        )
    }

    func mapToOperation(from dto: JointAccountsDTO.Response.Operation) throws -> JointAccountOperation {
        try mapToOperation(from: dto, txHash: nil)
    }

    func mapToSignature(from dto: JointAccountsDTO.Response.Operation.Vote) -> JointAccountOperation.Signature {
        JointAccountOperation.Signature(address: dto.address, state: mapSignatureState(from: dto.vote), at: dto.votedAt)
    }

    func mapToSafeTransaction(from dto: JointAccountsDTO.SafeTx) throws -> SafeTransaction {
        let value = try bigUInt(dto.value, field: "value")
        let safeTxGas = try bigUInt(dto.safeTxGas, field: "safeTxGas")
        let baseGas = try bigUInt(dto.baseGas, field: "baseGas")
        let gasPrice = try bigUInt(dto.gasPrice, field: "gasPrice")
        let data = try callData(dto.data, field: "data")
        let nonce = try int(dto.nonce, field: "nonce")

        return SafeTransaction(
            to: dto.to,
            value: value,
            data: data,
            operation: dto.operation.rawValue,
            safeTxGas: safeTxGas,
            baseGas: baseGas,
            gasPrice: gasPrice,
            gasToken: dto.gasToken,
            refundReceiver: dto.refundReceiver,
            nonce: nonce
        )
    }
}

// MARK: - Operations history

extension JointAccountsNetworkMapper {
    func mapToHistoryPage(from response: JointAccountsDTO.Response.OperationsHistory) -> JointOperationsHistoryPage {
        JointOperationsHistoryPage(
            items: mapToHistoryItems(from: response.items),
            nextCursor: response.pagination.endCursor,
            startDeltaCursor: response.pagination.startDeltaCursor,
            hasMore: response.pagination.hasMore
        )
    }

    func mapToHistoryPage(from response: JointAccountsDTO.Response.OperationsHistoryDelta) -> JointOperationsHistoryPage {
        JointOperationsHistoryPage(
            items: mapToHistoryItems(from: response.items),
            nextCursor: response.pagination.startCursor,
            startDeltaCursor: nil,
            hasMore: response.pagination.hasMore
        )
    }

    func mapToHistoryItem(from dto: JointAccountsDTO.Response.HistoryOperation) throws -> JointOperationHistoryItem {
        let operation = try mapToOperation(from: dto.operation, txHash: dto.txHash?.lowercased())
        let createdAt = try date(dto.operation.createdAt, field: "createdAt")
        let finishedAt = try dto.finishedAt.map { try date($0, field: "finishedAt") }

        return JointOperationHistoryItem(
            operation: operation,
            cryptoAccountId: dto.cryptoAccountId,
            safeAddress: dto.safeAddress.lowercased(),
            createdAt: createdAt,
            finishedAt: finishedAt,
            threshold: dto.operation.threshold,
            cancelReason: mapCancelReason(from: dto.cancelReason, operationId: dto.operation.operationId)
        )
    }
}

// MARK: - Private

private extension JointAccountsNetworkMapper {
    static let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    static let dateFallbackFormatter = ISO8601DateFormatter()

    func mapToOperation(from dto: JointAccountsDTO.Response.Operation, txHash: String?) throws -> JointAccountOperation {
        let signatures = dto.votes?.map(mapToSignature(from:)) ?? []
        let safeTransaction = try mapToSafeTransaction(from: dto.safeTx)
        let status = mapStatus(from: dto.status)

        return JointAccountOperation(
            id: dto.operationId,
            chainId: dto.chainId,
            safeTransaction: safeTransaction,
            status: status,
            txHash: txHash,
            initiator: dto.initiator,
            signatures: signatures
        )
    }

    func mapToHistoryItems(from dtos: [JointAccountsDTO.Response.HistoryOperation]) -> [JointOperationHistoryItem] {
        dtos.compactMap { dto in
            do {
                return try mapToHistoryItem(from: dto)
            } catch {
                JointAccountsLogger.warning("Skipping the joint operation '\(dto.operation.operationId)' of the history: \(error)")
                return nil
            }
        }
    }

    func mapCancelReason(from rawValue: String?, operationId: String) -> JointOperationCancelReason? {
        guard let rawValue else {
            return nil
        }

        switch rawValue {
        case "initiator":
            return .initiator
        case "threshold":
            return .threshold
        default:
            JointAccountsLogger.warning("The joint operation '\(operationId)' was cancelled for a reason this version has never heard of: \(rawValue)")
            return nil
        }
    }

    func date(_ string: String, field: String) throws -> Date {
        guard let date = Self.dateFormatter.date(from: string) ?? Self.dateFallbackFormatter.date(from: string) else {
            throw JointAccountsNetworkMapperError.malformedOperation(field: field)
        }

        return date
    }

    func mapStatus(from dto: JointAccountsDTO.Response.JointAccount) throws -> JointAccountStatus {
        switch dto.status {
        case .pending:
            return .pending
        case .confirming:
            // Taken as it comes: an answer that names the stage without the address is the one account's problem,
            // and refusing it here would cost the whole list its refresh
            return .confirming(safeAddress: dto.safeAddress)
        case .active:
            guard let safeAddress = dto.safeAddress else {
                throw JointAccountsNetworkMapperError.activeAccountWithoutAddress
            }

            return .active(safeAddress: safeAddress)
        case .cancelled:
            return .cancelled
        case .none:
            return .unknown
        }
    }

    func mapStatus(from status: JointAccountsDTO.Response.Operation.Status?) -> JointAccountOperationStatus {
        switch status {
        case .awaitingSignatures: .awaitingSignatures
        case .pending: .pending
        case .executed: .executed
        case .failed: .failed
        case .cancelled: .cancelled
        case .none: .unknown
        }
    }

    func mapSignatureState(from answer: JointAccountsDTO.Response.Operation.Vote.Answer?) -> JointAccountOperation.Signature.State {
        switch answer {
        case .approve: .signed
        case .reject: .declined
        case .none: .unknown
        }
    }

    /// - Note: `Data(hexString:)` answers a string it cannot read with an empty one, which here is the calldata of a
    /// plain transfer — a shape the co-signer would be shown and asked to sign in place of what was created. So the
    /// string is checked before it is read, and an empty one is only ever an empty one.
    func callData(_ string: String, field: String) throws -> Data {
        guard string.removeHexPrefix().isValidHex else {
            throw JointAccountsNetworkMapperError.malformedOperation(field: field)
        }

        return Data(hexString: string)
    }

    func bigUInt(_ string: String, field: String) throws -> BigUInt {
        guard let value = BigUInt(string) else {
            throw JointAccountsNetworkMapperError.malformedOperation(field: field)
        }

        return value
    }

    /// - Note: Every figure the contract speaks in is a `uint256`, so a negative one is as malformed as a word: it
    /// would reach the EIP-712 digest, where a `uint256` below zero is not an error but a trap.
    func int(_ string: String, field: String) throws -> Int {
        guard let value = Int(string), value >= 0 else {
            throw JointAccountsNetworkMapperError.malformedOperation(field: field)
        }

        return value
    }

    /// The Safe transaction keeps the kind as the contract's number; the endpoint is only told the two it knows.
    func operation(_ value: Int) throws -> JointAccountsDTO.SafeTx.Operation {
        guard let operation = JointAccountsDTO.SafeTx.Operation(rawValue: value) else {
            throw JointAccountsNetworkMapperError.malformedOperation(field: "operation")
        }

        return operation
    }
}

// MARK: - Error

enum JointAccountsNetworkMapperError: Error, Equatable {
    /// An activated account is operated at its address, so an answer naming the one without the other names
    /// nothing the app could show or spend from.
    case activeAccountWithoutAddress
    /// A figure of an operation that is not a base-10 integer cannot be hashed, so the operation could be neither
    /// signed nor shown.
    case malformedOperation(field: String)
}
