//
//  WalletModel+JointAccountPendingOperations.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

extension WalletModel {
    var jointOperationsAwaitingSignaturesPublisher: AnyPublisher<[JointAccountPendingOperation], Never> {
        guard let jointAccount = account as? any JointAccountModel else {
            return .just(output: [])
        }

        let tokenItem = tokenItem

        return jointAccount
            .jointAccountPendingOperationsProvider
            .pendingOperationsPublisher
            .map { operations in
                operations.filter { $0.operation.status == .awaitingSignatures && $0.tokenItem == tokenItem }
            }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    var jointOperationsAwaitingOwnSignaturePublisher: AnyPublisher<[JointAccountPendingOperation], Never> {
        guard let jointAccount = account as? any JointAccountModel else {
            return .just(output: [])
        }

        let signersResolver = JointAccountOperationSignersResolver()

        return jointOperationsAwaitingSignaturesPublisher
            .combineLatest(jointAccount.jointAccountMembersService.slotsPublisher)
            .map { operations, _ in operations.filter(signersResolver.canSign) }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}
