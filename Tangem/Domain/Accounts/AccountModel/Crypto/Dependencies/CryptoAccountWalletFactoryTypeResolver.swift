//
//  CryptoAccountWalletFactoryTypeResolver.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemFoundation

struct CryptoAccountWalletFactoryTypeResolver {
    let userWalletId: UserWalletId
    let jointAccountsRepository: JointAccountsRepository

    func resolve(derivationIdentity: CryptoAccountDerivationIdentity) -> WalletFactoryProvider.WalletFactoryType {
        switch derivationIdentity.type {
        case .crypto:
            return .owner
        case .joint:
            let accountId = CryptoAccountModelId(userWalletId: userWalletId, derivationIdentity: derivationIdentity)
            // Hoisted out of the predicate: the identifier is minted by hashing, and the list is searched linearly
            let identifier = accountId.rawValue.hexString
            let jointAccount = jointAccountsRepository.jointAccounts.first(where: { storedJointAccount in
                storedJointAccount.cryptoAccountId.caseInsensitiveEquals(to: identifier)
            })

            // Activation is the only thing that hands the account an address — see `JointAccountStatus.active`
            guard case .active(let safeAddress) = jointAccount?.status else {
                return .joint(safeAddress: nil)
            }

            return .joint(safeAddress: safeAddress)
        }
    }
}
