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
    var groupingOption: AnyPublisher<OrganizeTokensOptions.Grouping, Never> { get }
    var sortingOption: AnyPublisher<OrganizeTokensOptions.Sorting, Never> { get }
}
