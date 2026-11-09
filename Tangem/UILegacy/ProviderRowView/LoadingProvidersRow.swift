//
//  LoadingProvidersRow.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets

struct LoadingProvidersRow: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Localization.expressProvider)
                .style(Fonts.Regular.footnote, color: DesignSystem.Color.textSecondary)

            HStack(spacing: 4) {
                progressView

                Text(Localization.expressFetchBestRates)
                    .style(Fonts.Regular.subheadline, color: DesignSystem.Color.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var progressView: some View {
        ProgressView()
            .controlSize(.small)
            .frame(width: 16, height: 16)
            .padding(.vertical, 2)
    }
}

#Preview {
    LoadingProvidersRow()
        .padding()
        .background(DesignSystem.Color.bgPrimary)
}
