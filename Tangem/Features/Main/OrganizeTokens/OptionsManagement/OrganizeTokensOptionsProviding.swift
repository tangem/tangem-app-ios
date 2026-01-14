//
//  OrganizeTokensOptionsProviding.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol OrganizeTokensOptionsProviding {
    var groupingOption: UserTokensReorderingOptions.Grouping { get }
    var sortingOption: UserTokensReorderingOptions.Sorting { get }

    var groupingOptionPublisher: AnyPublisher<UserTokensReorderingOptions.Grouping, Never> { get }
    var sortingOptionPublisher: AnyPublisher<UserTokensReorderingOptions.Sorting, Never> { get }
}
