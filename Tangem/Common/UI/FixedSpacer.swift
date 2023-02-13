//
//  FixedSpacer.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

/// Spacer with fixed height
struct FixedSpacer: View {
    let height: CGFloat

    var body: some View {
        Spacer()
            .frame(height: height)
    }
}
