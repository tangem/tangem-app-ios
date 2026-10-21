//
//  AccountValidationFlow.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

enum AccountValidationFlow {
    case new(newAccountName: String, accountType: AccountType, remoteState: CryptoAccountsRemoteState)
    case edit(newAccountName: String?, derivationIdentity: CryptoAccountDerivationIdentity, remoteState: CryptoAccountsRemoteState)
    case archive(identifier: any AccountModelPersistentIdentifierConvertible, accountModelPublisher: AnyPublisher<any CryptoAccountModel, Never>)
    case unarchive(info: ArchivedCryptoAccountInfo, remoteState: CryptoAccountsRemoteState)
}
