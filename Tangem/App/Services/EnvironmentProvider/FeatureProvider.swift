//
//  FeatureProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

// MARK: - Provider

// Use this provider for your feature
// Will be expand for control availability version
enum FeatureProvider {
    static func isAvailable(_ toggle: FeatureToggle) -> Bool {
        EnvironmentProvider.shared.availableFeatures.contains(toggle)
    }
}

// MARK: - Keys

enum FeatureToggle: String, Hashable, CaseIterable {
    case test

    var name: String {
        switch self {
        case .test: return "Test (will be added in the future)"
        }
    }
}
