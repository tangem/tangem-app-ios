//
//  FeatureStateRowViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct FeatureStateRowViewModel: Hashable, Identifiable {
    var id: Feature { feature }

    let feature: Feature
    let enabledByDefault: Bool
    let state: BindingValue<FeatureState>

    var releaseVersionInfo: String {
        feature.releaseVersion.version ?? "Unspecified"
    }

    var defaultState: String {
        enabledByDefault ? "Enabled" : "Disabled"
    }
}
