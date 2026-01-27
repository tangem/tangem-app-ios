//
//  CurrencySelectViewEvent.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

enum CurrencySelectViewEvent {
    case viewDidAppear
    case currencySelected(CurrencySelectViewState.CurrencyItem)
    case searchTextUpdated(String)
}
