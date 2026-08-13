//
//  TangemPayCashbackAdditionalSection.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemUIUtils
import TangemAssets
import TangemLocalization

struct TangemPayCashbackAdditionalSection: View {
    let promotions: [TangemPayCashbackDetailViewData.AdditionalPromotion]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(Localization.tangempayCashbackAdditionalTitle)
                .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textPrimary)
                .padding(.vertical, 16)

            VStack(spacing: 12) {
                ForEach(promotions) { promotion in
                    TangemPayCashbackAdditionalRow(promotion: promotion)
                }
            }
            .padding(.vertical, 12)
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    ScrollView {
        TangemPayCashbackAdditionalSection(promotions: TangemPayCashbackDetailViewData.preview.additionalPromotions)
            .padding(.horizontal, 16)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
}
#endif
