//
//  AuxiliaryTypes.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

@available(iOS 16.0, *)
enum RoundedCornersVerticalEdge {
    case topEdge
    case bottomEdge
    case all
}

struct RoundedCornersConfiguration {
    var topLeadingRadius: CGFloat = 0.0
    var bottomLeadingRadius: CGFloat = 0.0
    var bottomTrailingRadius: CGFloat = 0.0
    var topTrailingRadius: CGFloat = 0.0
}
