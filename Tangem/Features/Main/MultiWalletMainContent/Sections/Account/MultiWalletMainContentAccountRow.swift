//
//  MultiWalletMainContentAccountRow.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum MultiWalletMainContentAccountRow: Identifiable {
    case account(MultiWalletMainContentAccountSection)
    case collectibles(AccountRowButtonViewModel)

    var id: AnyHashable {
        switch self {
        case .account(let section): section.id
        case .collectibles(let viewModel): viewModel.id
        }
    }

    var accountPersistentIdentifier: AnyHashable {
        switch self {
        case .account(let section): section.model.accountPersistentIdentifier
        case .collectibles: AccountModelUtils.collectiblesAccountDerivationIdentity.toPersistentIdentifier()
        }
    }
}
