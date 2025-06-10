//
//  AnyTransition+opacityLinear.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

extension AnyTransition {
    static func opacityLinear(duration: TimeInterval = 0.15) -> AnyTransition {
        .opacity.animation(.linear(duration: duration))
    }
}
