//
//  AuthWalletViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation

final class AuthWalletViewModel: ObservableObject {
    var icon: UserWalletIcon {
        item.icon
    }

    var title: String {
        item.title
    }

    var description: String {
        item.description
    }

    var isProtected: Bool {
        item.isProtected
    }

    private let item: AuthViewState.WalletItem

    init(item: AuthViewState.WalletItem) {
        self.item = item
    }
}

// MARK: - Internal methods

extension AuthWalletViewModel {
    func onTap() {
        item.action()
    }

    func isUnlocking(with userWalletId: UserWalletId?) -> Bool {
        item.isUnlocking(userWalletId)
    }
}
