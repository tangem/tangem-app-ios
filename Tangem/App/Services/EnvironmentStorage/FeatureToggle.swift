//
//  FeatureToggle.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

enum FeatureToggle: String, Hashable, CaseIterable {
    case test
    
    var name: String {
        switch self {
        case .test: return "Test (will be able in future)"
        }
    }
}
