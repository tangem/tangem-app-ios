//
//  WelcomeV2ViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

final class WelcomeV2ViewModel: ObservableObject {
    private weak var coordinator: WelcomeV2Routable?

    init(coordinator: WelcomeV2Routable) {
        self.coordinator = coordinator
    }
}
