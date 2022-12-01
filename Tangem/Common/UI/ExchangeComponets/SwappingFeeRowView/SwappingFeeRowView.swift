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
            Text("swapping_fee".localized)
                .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

            Spacer()

            Text(viewModel.fee)
                .style(Fonts.Regular.footnote, color: Colors.Text.primary1)
        }
        .lineLimit(1)
        .padding(.vertical, 14)
        .background(Colors.Background.primary)
    }
}

struct SwappingFeeRowView_Previews: PreviewProvider {
    static let viewModel = SwappingFeeRowViewModel(fee: "0.155 MATIC (0.14 $)")
    static var previews: some View {
        ZStack {
            Colors.Background.secondary

            GroupedSection(viewModel) {
                SwappingFeeRowView(viewModel: $0)
            }
            .padding()
        }
    }
}
