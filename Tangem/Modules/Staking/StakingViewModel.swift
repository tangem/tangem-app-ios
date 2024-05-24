//
//  StakingViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI

final class StakingViewModel: ObservableObject {
    // MARK: - ViewState

    // MARK: - Dependencies

    private weak var coordinator: StakingRoutable?

    init(
        coordinator: StakingRoutable
    ) {
        self.coordinator = coordinator
    }
}
