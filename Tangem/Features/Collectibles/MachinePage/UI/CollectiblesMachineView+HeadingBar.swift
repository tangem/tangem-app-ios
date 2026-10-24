//
//  CollectiblesMachineView+HeadingBar.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

extension CollectiblesMachineView {
    struct HeadingBar: View {
        var body: some View {
            Shimmer()
                .frame(width: 101, height: 12)
                .clipShape(Capsule())
                .frame(height: 18)
        }
    }
}
