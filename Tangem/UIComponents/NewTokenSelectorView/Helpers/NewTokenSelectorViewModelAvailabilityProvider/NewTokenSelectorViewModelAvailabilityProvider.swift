//
//  NewTokenSelectorViewModelAvailabilityProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

protocol NewTokenSelectorViewModelAvailabilityProvider: AnyObject {
    func isAvailable(item: NewTokenSelectorItem) -> NewTokenSelectorItemViewModel.DisabledReason?
}
