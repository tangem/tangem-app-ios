//
//  UserWalletInfo.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemFoundation

struct UserWalletInfo {
    let name: String
    let id: UserWalletId
    let config: UserWalletConfig
    let hasMultipleAccounts: Bool
    let refcode: Refcode?
    let signer: any TangemSigner
    let emailDataProvider: any EmailDataProvider
}

// MARK: - Equatable

extension UserWalletInfo: Equatable {
    static func == (lhs: UserWalletInfo, rhs: UserWalletInfo) -> Bool {
        lhs.id == rhs.id && lhs.name == rhs.name
    }
}

// MARK: - Hashable

extension UserWalletInfo: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
    }
}

// MARK: - UserWalletModel+

extension UserWalletModel {
    var userWalletInfo: UserWalletInfo {
        let hasMultipleAccounts = accountModelsManager.accountModels.contains(where: { accountModel in
            switch accountModel {
            case .standard(let cryptoAccounts): cryptoAccounts.state == .multiple
            }
        })

        return UserWalletInfo(
            name: name,
            id: userWalletId,
            config: config,
            hasMultipleAccounts: hasMultipleAccounts,
            refcode: refcodeProvider?.getRefcode(),
            signer: signer,
            emailDataProvider: self
        )
    }
}
