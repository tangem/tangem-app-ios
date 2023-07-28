//
//  SingleWalletContentViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI

final class SingleWalletContentViewModel: ObservableObject {
    // MARK: - ViewState

    // MARK: - Dependencies

    private unowned let coordinator: SingleWalletContentRoutable

    init(
        coordinator: SingleWalletContentRoutable
    ) {
        self.coordinator = coordinator
    }
}
