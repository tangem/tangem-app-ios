//
//  SendWalletInfo.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemFoundation

struct SendWalletInfo {
    let name: String
    let id: UserWalletId
    let config: UserWalletConfig
    let signer: any TangemSigner
    let emailDataProvider: any EmailDataProvider
}

// MARK: - Equatable

extension SendWalletInfo: Equatable {
    static func == (lhs: SendWalletInfo, rhs: SendWalletInfo) -> Bool {
        lhs.id == rhs.id && lhs.name == rhs.name
    }
}

// MARK: - Hashable

extension SendWalletInfo: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
    }
}

// MARK: - UserWalletModel+

extension UserWalletModel {
    var sendWalletInfo: SendWalletInfo {
        .init(
            name: name,
            id: userWalletId,
            config: config,
            signer: signer,
            emailDataProvider: self
        )
    }
}
