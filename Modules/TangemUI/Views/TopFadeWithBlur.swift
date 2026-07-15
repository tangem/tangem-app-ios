//
//  TopFadeWithBlur.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import BlurSwiftUI

struct TopFadeWithBlur: View {
    var body: some View {
        VariableBlur(direction: .down)
            .dimmingAlpha(.constant(alpha: 0.5))
            .dimmingOvershoot(nil)
            .frame(maxWidth: .infinity)
            .allowsHitTesting(false)
    }
}
