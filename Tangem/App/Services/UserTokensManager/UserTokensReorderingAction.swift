//
//  UserTokensReorderingAction.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

enum UserTokensReorderingAction {
    case setGroupingOption(option: OrganizeTokensOptions.Grouping)
    case setSortingOption(option: OrganizeTokensOptions.Sorting)
    case reorder(reorderedWalletModelIds: [WalletModel.ID])
}
