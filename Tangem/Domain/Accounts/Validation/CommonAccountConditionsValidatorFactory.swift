//
//  CommonAccountConditionsValidatorFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct CommonAccountConditionsValidatorFactory {
    let userWalletId: UserWalletId
}

// MARK: - AccountConditionsValidatorFactory protocol conformance

extension CommonAccountConditionsValidatorFactory: AccountConditionsValidatorFactory {
    func makeValidator(for flow: AccountValidationFlow) -> any CryptoAccountConditionsValidator {
        switch flow {
        case .new(let newAccountName, let accountType, let remoteState):
            makeNewAccountValidator(newAccountName: newAccountName, accountType: accountType, remoteState: remoteState)
        case .edit(let newAccountName, let derivationIdentity, let remoteState):
            EditCryptoAccountConditionsValidator(
                newAccountName: newAccountName,
                derivationIdentity: derivationIdentity,
                remoteState: remoteState
            )
        case .archive(let identifier, let accountModelPublisher):
            ArchivedCryptoAccountConditionsValidator(
                userWalletId: userWalletId,
                accountIdentifier: identifier,
                accountModelPublisher: accountModelPublisher
            )
        case .unarchive(let info, let remoteState):
            makeUnarchivedAccountValidator(info: info, remoteState: remoteState)
        }
    }
}

// MARK: - Private

private extension CommonAccountConditionsValidatorFactory {
    func makeNewAccountValidator(
        newAccountName: String,
        accountType: AccountType,
        remoteState: CryptoAccountsRemoteState
    ) -> any CryptoAccountConditionsValidator {
        switch accountType {
        case .crypto:
            NewCryptoAccountConditionsValidator(newAccountName: newAccountName, remoteState: remoteState)
        case .joint:
            NewJointAccountConditionsValidator(newAccountName: newAccountName, remoteState: remoteState)
        }
    }

    func makeUnarchivedAccountValidator(
        info: ArchivedCryptoAccountInfo,
        remoteState: CryptoAccountsRemoteState
    ) -> any CryptoAccountConditionsValidator {
        switch info.derivationIdentity.type {
        case .crypto:
            UnarchivedCryptoAccountConditionsValidator(newAccountName: info.name, identifier: info.id, remoteState: remoteState)
        case .joint:
            UnarchivedJointAccountConditionsValidator(remoteState: remoteState)
        }
    }
}
