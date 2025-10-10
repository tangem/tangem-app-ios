//
//  NewTokenSelectorGroupedSectionWrapperViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine

final class NewTokenSelectorGroupedSectionWrapperViewModel: ObservableObject, Identifiable {
    @Published var isOpen: Bool = true

    let wallet: String
    let sections: [NewTokenSelectorGroupedSectionViewModel]

    init(isOpen: Bool, wallet: String, sections: [NewTokenSelectorGroupedSectionViewModel]) {
        self.isOpen = isOpen
        self.wallet = wallet
        self.sections = sections
    }
}
