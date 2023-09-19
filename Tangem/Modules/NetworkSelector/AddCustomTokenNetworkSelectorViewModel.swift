//
//  AddCustomTokenNetworkSelectorViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI

final class AddCustomTokenNetworkSelectorViewModel: ObservableObject {
    // MARK: - ViewState

    // MARK: - Dependencies

    private unowned let coordinator: AddCustomTokenNetworkSelectorRoutable

    init(
        coordinator: AddCustomTokenNetworkSelectorRoutable
    ) {
        self.coordinator = coordinator
    }
}
