//
//  PushNotificationsStepViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

class PushNotificationsStepViewModel: ObservableObject {
    private weak var routable: WelcomeOnboardingStepRoutable?

    init(routable: any WelcomeOnboardingStepRoutable) {
        self.routable = routable
    }
}
