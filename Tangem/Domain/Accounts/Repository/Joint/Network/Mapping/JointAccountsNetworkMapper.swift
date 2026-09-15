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
        let signatures = dto.signatures.map(mapToSignature(from:))
        let safeTransaction = try mapToSafeTransaction(from: dto.safeTx)
        let status = mapStatus(from: dto.status)

        return JointAccountOperation(
            id: dto.operationId,
            chainId: dto.chainId,
            safeTransaction: safeTransaction,
            status: status,
            initiator: dto.initiator,
            signatures: signatures
        )
    }

    func mapToSignature(from dto: JointAccountsDTO.Response.Operation.Signature) -> JointAccountOperation.Signature {
        JointAccountOperation.Signature(address: dto.address, state: mapSignatureState(from: dto.state), at: dto.at)
    }

    func mapToSafeTransaction(from dto: JointAccountsDTO.SafeTx) throws -> SafeTransaction {
        let value = try bigUInt(dto.value, field: "value")
        let safeTxGas = try bigUInt(dto.safeTxGas, field: "safeTxGas")
        let baseGas = try bigUInt(dto.baseGas, field: "baseGas")
        let gasPrice = try bigUInt(dto.gasPrice, field: "gasPrice")
        let data = try callData(dto.data, field: "data")

        return SafeTransaction(
            to: dto.to,
            value: value,
            data: data,
            operation: dto.operation,
            safeTxGas: safeTxGas,
            baseGas: baseGas,
            gasPrice: gasPrice,
            gasToken: dto.gasToken,
            refundReceiver: dto.refundReceiver,
            nonce: dto.nonce
        )
    }
}

// MARK: - Private

private extension JointAccountsNetworkMapper {
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
        case .none: .unknown
        }
    }

    func mapSignatureState(from state: JointAccountsDTO.Response.Operation.Signature.State?) -> JointAccountOperation.Signature.State {
        switch state {
        case .signed: .signed
        case .declined: .declined
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
}

// MARK: - Error

enum JointAccountsNetworkMapperError: Error, Equatable {
    /// An activated account is operated at its address, so an answer naming the one without the other names
    /// nothing the app could show or spend from.
    case activeAccountWithoutAddress
    /// A gas or value figure of an operation that is not a base-10 integer cannot be hashed, so the operation could
    /// be neither signed nor shown.
    case malformedOperation(field: String)
}
