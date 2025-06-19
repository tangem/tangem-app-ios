//
//  ImportWalletSelectorViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine

final class ImportWalletSelectorViewModel: ObservableObject {
    private weak var coordinator: ImportWalletSelectorRoutable?

    init(coordinator: ImportWalletSelectorRoutable) {
        self.coordinator = coordinator
    }
}
