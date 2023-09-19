//
//  AddCustomTokenDerivationPathSelectorViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI

final class AddCustomTokenDerivationPathSelectorViewModel: ObservableObject {
    // MARK: - ViewState

    // MARK: - Dependencies

    private unowned let coordinator: AddCustomTokenDerivationPathSelectorRoutable

    init(
        coordinator: AddCustomTokenDerivationPathSelectorRoutable
    ) {
        self.coordinator = coordinator
    }
}
