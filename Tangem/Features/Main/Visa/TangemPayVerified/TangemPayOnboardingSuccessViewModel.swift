//
//  TangemPayOnboardingSuccessViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

final class TangemPayOnboardingSuccessViewModel: ObservableObject {
    private weak var coordinator: TangemPayOnboardingSuccessRoutable?

    init(coordinator: TangemPayOnboardingSuccessRoutable?) {
        self.coordinator = coordinator
    }

    func close() {
        coordinator?.closeOnboardingSuccess()
    }
}

protocol TangemPayOnboardingSuccessRoutable: AnyObject {
    func closeOnboardingSuccess()
}
