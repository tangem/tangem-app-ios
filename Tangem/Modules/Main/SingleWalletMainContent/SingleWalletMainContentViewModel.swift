//
//  SingleWalletMainContentViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine

final class SingleWalletMainContentViewModel: ObservableObject {
    // MARK: - ViewState

    // MARK: - Dependencies

    private unowned let coordinator: SingleWalletMainContentRoutable

    init(
        coordinator: SingleWalletMainContentRoutable
    ) {
        self.coordinator = coordinator
    }
}
