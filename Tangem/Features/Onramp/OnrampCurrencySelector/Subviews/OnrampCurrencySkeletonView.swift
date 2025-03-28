//
//  OnrampCurrencySkeletonView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct OnrampCurrencySkeletonView: View {
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            SkeletonView()
                .frame(width: 36, height: 36)
                .cornerRadiusContinuous(18)

            VStack(alignment: .leading, spacing: 6) {
                SkeletonView()
                    .frame(width: 70, height: 12)
                    .cornerRadiusContinuous(3)

                SkeletonView()
                    .frame(width: 52, height: 12)
                    .cornerRadiusContinuous(3)
            }
        }
        .padding(.vertical, 14)
    }
}
