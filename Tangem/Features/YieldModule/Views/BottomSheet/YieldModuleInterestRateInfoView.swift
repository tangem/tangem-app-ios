//
//  YieldModuleInterestRateInfoView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

extension YieldModuleBottomSheetView {
    struct YieldModuleInterestRateInfoView: View {
        let lastYearReturns: [String: Double]

        var body: some View {
            Rectangle()
                .fill(Color.white)
                .frame(maxWidth: .infinity)
                .frame(height: 200)
        }
    }
}
