//
//  CurrencySelectViewState.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemFoundation

struct CurrencySelectViewState {
    var contentState: LoadingResult<[CurrencyItem], any Error>
    var searchText: String

    static let initial = CurrencySelectViewState(contentState: .loading, searchText: "")
}

extension CurrencySelectViewState {
    struct CurrencyItem: Identifiable, Equatable {
        var id: String { code }

        let code: String
        let title: String
        var isSelected: Bool
    }
}
