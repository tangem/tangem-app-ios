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
    func mapToRequest<Payload: Encodable>(from blob: JointAccountSignedBlob<Payload>) -> JointAccountsDTO.SignedRequest<Payload> {
        JointAccountsDTO.SignedRequest(
            payload: blob.payload,
            signature: blob.signature.hexString.addHexPrefix()
        )
    }
}

// MARK: - Responses

extension JointAccountsNetworkMapper {
    func mapToCreationResult(from response: JointAccountsDTO.Create.Response) -> JointAccountCreationResult {
        let invites = (response.invites ?? []).map { JointAccountInvite(id: $0.id) }
        let freeSlotsCount = max(0, response.membersCount - response.members.count)

        if invites.count != freeSlotsCount {
            // Neither reissued nor readable afterwards, so a slot that came back without an invite can never be
            // filled — worth seeing in the logs of a wallet whose creator turns out unable to invite anybody
            JointAccountsLogger.warning("A joint account was created with \(invites.count) invites for \(freeSlotsCount) free slots")
        }

        return JointAccountCreationResult(account: mapToJointAccount(from: response), invites: invites)
    }

    func mapToJointAccounts(from response: JointAccountsDTO.List.Response) -> [RemoteJointAccount] {
        response.jointAccounts.map(mapToJointAccount(from:))
    }

    func mapToJointAccount(from dto: JointAccountsDTO.JointAccount) -> RemoteJointAccount {
        RemoteJointAccount(
            cryptoAccountId: dto.cryptoAccountId,
            membersCount: dto.membersCount,
            threshold: dto.threshold,
            address: dto.safeAddress,
            status: dto.status,
            members: dto.members.map { member in
                StoredJointAccount.Member(name: member.name, address: member.address, role: member.role)
            }
        )
    }

    func mapToInvitePreview(from response: JointAccountsDTO.InvitePreview.Response) -> JointAccountInvitePreview {
        JointAccountInvitePreview(
            config: response.config,
            creator: JointAccountInvitePreview.Creator(name: response.creator.name, address: response.creator.address)
        )
    }
}
