//
//  FeatureStateRowViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct FeatureStateRowViewModel {
    let toggle: Feature
    let isEnabledByDefault: Bool
    let state: Binding<FeatureState>

    var releaseVersionInfo: String {
        toggle.releaseVersion.version ?? "unspecified"
    }

    var stateByDefault: String {
        isEnabledByDefault ? "Enabled" : "Disabled"
    }
}

extension FeatureStateRowViewModel: Identifiable {
    var id: Int { hashValue }
}

extension FeatureStateRowViewModel: Hashable {
    static func == (lhs: FeatureStateRowViewModel, rhs: FeatureStateRowViewModel) -> Bool {
        lhs.hashValue == rhs.hashValue
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(toggle)
        hasher.combine(state.wrappedValue)
    }
}
