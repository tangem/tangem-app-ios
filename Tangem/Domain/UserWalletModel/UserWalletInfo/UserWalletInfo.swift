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
