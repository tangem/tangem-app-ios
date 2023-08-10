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
    func group(by groupingOption: OrganizeTokensOptions.Grouping)
    func sort(by sortingOption: OrganizeTokensOptions.Sorting)
    func save() -> AnyPublisher<Void, Never>
}
