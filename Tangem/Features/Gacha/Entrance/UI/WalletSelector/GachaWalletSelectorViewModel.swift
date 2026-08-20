//
//  GachaWalletSelectorViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemUI

final class GachaWalletSelectorViewModel: FloatingSheetContentViewModel {
    let accountSelectorViewModel: AccountSelectorViewModel
    let close: () -> Void

    init(accountSelectorViewModel: AccountSelectorViewModel, close: @escaping () -> Void) {
        self.accountSelectorViewModel = accountSelectorViewModel
        self.close = close
    }
}
