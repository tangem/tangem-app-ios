//
//  LoadingProvidersRow.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct LoadingProvidersRow: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Localization.expressProvider)
                .style(Fonts.Regular.footnote, color: Colors.Text.secondary)

            HStack(spacing: 4) {
                progressView

                Text(Localization.expressFetchBestRates)
                    .style(Fonts.Regular.subheadline, color: Colors.Text.tertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var progressView: some View {
        ProgressView()
            .controlSize(.small)
    }
}

#Preview {
    LoadingProvidersRow()
        .padding()
        .background(Colors.Background.secondary)
}
