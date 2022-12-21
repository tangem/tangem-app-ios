//
//  SwappingFeeRowView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct SwappingFeeRowView: View {
    private let viewModel: SwappingFeeRowViewModel

    init(viewModel: SwappingFeeRowViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        HStack {
            Text(L10n.sendFeeLabel)
                .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

            Spacer()

            Text(viewModel.formattedFee)
                .style(Fonts.Regular.footnote, color: Colors.Text.primary1)
                .skeletonable(isShown: viewModel.isLoading, size: CGSize(width: 100, height: 11))
        }
        .lineLimit(1)
        .padding(.vertical, 14)
        .background(Colors.Background.primary)
    }
}

struct SwappingFeeRowView_Previews: PreviewProvider {
    static let viewModel = SwappingFeeRowViewModel(
        state: .fee(fee: "0.0000000000155", symbol: "MATIC", fiat: "$0.14")
    )

    static let loadingViewModel = SwappingFeeRowViewModel(
        state: .loading
    )

    static var previews: some View {
        ZStack {
            Colors.Background.secondary

            GroupedSection([viewModel, loadingViewModel]) {
                SwappingFeeRowView(viewModel: $0)
            }
            .padding()
        }
    }
}
