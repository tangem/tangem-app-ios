//
//  FeatureToggleProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

// Use this provider for your feature
enum FeatureProvider {
    static func isAvailable(_ toggle: FeatureToggle) -> Bool {
        EnvironmentStorage.integratedFeatures.contains(toggle.rawValue)
    }
}
