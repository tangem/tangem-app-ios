//
//  InterestRateInfo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization

extension YieldPromoBottomSheetView {
    struct InterestRateInfo: View {
        let lastYearReturns: [String: Double]

        var body: some View {
            Rectangle()
                .fill(Color.white)
                .frame(maxWidth: .infinity)
                .frame(height: 200)
        }
    }
}
