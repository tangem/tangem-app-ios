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
    var orderedWalletModelIds: AnyPublisher<[WalletModelId.ID], Never> { get }
    var groupingOption: UserTokensReorderingOptions.Grouping { get }
    var sortingOption: UserTokensReorderingOptions.Sorting { get }

    var groupingOptionPublisher: AnyPublisher<UserTokensReorderingOptions.Grouping, Never> { get }
    var sortingOptionPublisher: AnyPublisher<UserTokensReorderingOptions.Sorting, Never> { get }

    func reorder(_ actions: [UserTokensReorderingAction], source: UserTokensReorderingSource) -> AnyPublisher<Void, Never>
}
