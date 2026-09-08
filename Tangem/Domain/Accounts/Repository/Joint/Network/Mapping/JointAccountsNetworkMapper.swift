//
//  JointAccountsNetworkMapper.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
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
        let invites = (response.invites ?? []).map { JointAccountInvite(id: $0.id) }
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
        try RemoteJointAccount(
            cryptoAccountId: dto.cryptoAccountId,
            membersCount: dto.membersCount,
            threshold: dto.threshold,
            status: mapStatus(from: dto),
            members: dto.members.map { member in
                StoredJointAccount.Member(name: member.name, address: member.address, role: member.role, inviteId: member.inviteId)
            }
        )
    }

    func mapToInvitePreview(from response: JointAccountsDTO.Response.InvitePreview) -> JointAccountInvitePreview {
        JointAccountInvitePreview(
            config: response.config,
            creator: JointAccountInvitePreview.Creator(name: response.creator.name, address: response.creator.address)
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
            return .confirming
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
}

// MARK: - Error

enum JointAccountsNetworkMapperError: Error, Equatable {
    /// An activated account is operated at its address, so an answer naming the one without the other names
    /// nothing the app could show or spend from.
    case activeAccountWithoutAddress
}
