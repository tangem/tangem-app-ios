//
//  EnvironmentToggleRowViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct EnvironmentToggleRowViewModel {
    let toggle: FeatureToggle
    let state: Binding<SegmentViewPicker>
}

enum SegmentViewPicker: String, Hashable, Identifiable, CaseIterable {
    var id: String { rawValue }
    
    case `default`
    case off
    case on
}
