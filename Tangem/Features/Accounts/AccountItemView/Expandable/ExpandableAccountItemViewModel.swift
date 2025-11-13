//
//  ExpandableAccountItemViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

final class ExpandableAccountItemViewModel: ObservableObject {
    let accountItemViewModel: AccountItemViewModel

    init(accountItemViewModel: AccountItemViewModel) {
        self.accountItemViewModel = accountItemViewModel
    }
}
