//
//  PriceAlertsOnboardingViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

final class PriceAlertsOnboardingViewModel: ObservableObject {
    let gotItAction: () -> Void
    let closeAction: () -> Void

    init(gotItAction: @escaping () -> Void, closeAction: @escaping () -> Void) {
        self.gotItAction = gotItAction
        self.closeAction = closeAction
    }
}
