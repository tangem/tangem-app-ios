//
//  OrganizeTokensOptionsEditing.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol OrganizeTokensOptionsEditing {
    func group(by groupingOption: UserTokensReorderingOptions.Grouping)
    func sort(by sortingOption: UserTokensReorderingOptions.Sorting)
    func save(reorderedWalletModelIds: [WalletModel.ID], source: UserTokensReorderingSource) -> AnyPublisher<Void, Never>
}
