//
//  NewTokenSelectorViewModelSearchFilter.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

protocol NewTokenSelectorViewModelSearchFilter {
    func filter(list: NewTokenSelectorList, searchText: String) -> NewTokenSelectorList
}
