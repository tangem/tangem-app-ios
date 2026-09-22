//
//  JointAccountOperationSignersResolver.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemFoundation

struct JointAccountOperationSignersResolver {
    func ownAddress(of wallet: JointAccountWallet) -> String? {
        let addressService = AddressServiceFactory(blockchain: JointAccountKeyPath.blockchain).makeAddressService()

        return try? addressService.makeAddress(for: wallet.publicKey, with: .default).value
    }

    func ownAnswer(of pendingOperation: JointAccountPendingOperation) -> Answer? {
        guard let ownAddress = ownAddress(of: pendingOperation.wallet) else {
            return nil
        }

        return answer(of: ownAddress, in: pendingOperation.operation)
    }

    func answer(of address: String, in operation: JointAccountOperation) -> Answer {
        if address.caseInsensitiveEquals(to: operation.initiator) {
            return .created
        }

        let signature = operation.signatures.first { $0.address.caseInsensitiveEquals(to: address) }

        return switch signature?.state {
        case .signed: .signed
        case .declined: .declined
        case .unknown, .none: .waiting
        }
    }

    func canSign(_ pendingOperation: JointAccountPendingOperation) -> Bool {
        guard let ownAddress = ownAddress(of: pendingOperation.wallet) else {
            return false
        }

        let operation = pendingOperation.operation
        let members = pendingOperation.wallet.account?.jointAccountMembersService.slots.members ?? []

        guard members.contains(where: { $0.address.caseInsensitiveEquals(to: ownAddress) }) else {
            return false
        }

        guard operation.status == .awaitingSignatures else {
            return false
        }

        guard !ownAddress.caseInsensitiveEquals(to: operation.initiator) else {
            return false
        }

        return !operation.signatures.contains { $0.address.caseInsensitiveEquals(to: ownAddress) }
    }
}

// MARK: - Auxiliary types

extension JointAccountOperationSignersResolver {
    enum Answer {
        case created
        case signed
        case declined
        case waiting
    }
}
