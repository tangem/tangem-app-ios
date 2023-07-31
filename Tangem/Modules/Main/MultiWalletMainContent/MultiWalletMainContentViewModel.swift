//
//  MultiWalletMainContentViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine

final class MultiWalletMainContentViewModel: ObservableObject {
    // MARK: - ViewState

    // MARK: - Dependencies

    private unowned let coordinator: MultiWalletMainContentRoutable

    init(
        coordinator: MultiWalletMainContentRoutable
    ) {
        self.coordinator = coordinator
    }
}
