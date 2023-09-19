//
//  NetworkSelectorViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI

final class NetworkSelectorViewModel: ObservableObject {
    // MARK: - ViewState

    // MARK: - Dependencies

    private unowned let coordinator: NetworkSelectorRoutable

    init(
        coordinator: NetworkSelectorRoutable
    ) {
        self.coordinator = coordinator
    }
}
