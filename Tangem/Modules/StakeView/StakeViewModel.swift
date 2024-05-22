//
//  StakeViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI

final class StakeViewModel: ObservableObject {
    // MARK: - ViewState

    // MARK: - Dependencies

    private weak var coordinator: StakeRoutable?

    init(
        coordinator: StakeRoutable
    ) {
        self.coordinator = coordinator
    }
}
