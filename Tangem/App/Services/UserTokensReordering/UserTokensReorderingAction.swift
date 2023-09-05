//
//  UserTokensReorderingAction.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

enum UserTokensReorderingAction {
    case setGroupingOption(option: UserTokensReorderingOptions.Grouping)
    case setSortingOption(option: UserTokensReorderingOptions.Sorting)
    case reorder(reorderedWalletModelIds: [WalletModel.ID])
}
