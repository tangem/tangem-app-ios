//
//  UserTokensReordering.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol UserTokensReordering {
    var orderedWalletModelIds: AnyPublisher<[WalletModel.ID], Never> { get }
    var groupingOption: AnyPublisher<UserTokensReorderingOptions.Grouping, Never> { get }
    var sortingOption: AnyPublisher<UserTokensReorderingOptions.Sorting, Never> { get }

    func reorder(_ actions: [UserTokensReorderingAction], source: UserTokensReorderingSource) -> AnyPublisher<Void, Never>
}
