//
//  TangemPayOnboardingScreenVersionProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum TangemPayOnboardingScreenVersion {
    case v1
    case v2
}

protocol TangemPayOnboardingScreenVersionProvider {
    func screenVersion() -> TangemPayOnboardingScreenVersion
}

struct CommonTangemPayOnboardingScreenVersionProvider: TangemPayOnboardingScreenVersionProvider {
    @Injected(\.experimentService) private var experimentService: ExperimentService

    func screenVersion() -> TangemPayOnboardingScreenVersion {
        let isNewOnboarding = experimentService.variant(.tangemPayOnboardingVariant)?.value == Variant.newOnboarding.rawValue
        return isNewOnboarding ? .v2 : .v1
    }
}

private extension CommonTangemPayOnboardingScreenVersionProvider {
    enum Variant: String {
        case newOnboarding = "newonboard_on"
    }
}
