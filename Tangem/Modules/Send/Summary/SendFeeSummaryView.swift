//
//  SendFeeSummaryView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct SendFeeSummaryView: View {
    let viewModel: SendFeeSummaryViewModel

    var body: some View {
        GroupedSection([viewModel]) { viewModel in
            VStack(alignment: .leading, spacing: 6) {
                Text(Localization.sendNetworkFeeTitle)
                    .style(Fonts.Regular.caption1, color: Colors.Text.secondary)

                Text(viewModel.fee)
                    .style(Fonts.Regular.footnote, color: Colors.Text.primary1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 14)
        }
        .horizontalPadding(14)
    }
}

#Preview {
    GroupedScrollView {
        SendFeeSummaryView(viewModel: SendFeeSummaryViewModel(fee: "0.159817 MATIC (0.22 $)"))

        SendFeeSummaryView(viewModel: SendFeeSummaryViewModel(fee: "0.159817159817159817159817159817159817159817159817 MATIC (0.2222222222222222222222222222222222222222222222 $)"))
    }
    .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
}
