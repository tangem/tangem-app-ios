//
//  MultiWalletContentViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine

final class MultiWalletContentViewModel: ObservableObject {
    // MARK: - ViewState

    // MARK: - Dependencies

    private unowned let coordinator: MultiWalletContentRoutable

    init(
        coordinator: MultiWalletContentRoutable
    ) {
        self.coordinator = coordinator
    }
}
