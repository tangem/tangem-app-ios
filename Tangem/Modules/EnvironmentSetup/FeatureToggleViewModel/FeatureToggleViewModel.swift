//
//  FeatureToggleViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

// [REDACTED_TODO_COMMENT]
struct FeatureToggleViewModel: Identifiable {
    var id: Int { toggle.hashValue }

    let toggle: FeatureToggle
    let isActive: Binding<Bool>
}

extension FeatureToggleViewModel: Equatable {
    static func == (lhs: FeatureToggleViewModel, rhs: FeatureToggleViewModel) -> Bool {
        lhs.id == rhs.id
    }
}

