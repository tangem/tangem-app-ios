//
//  ExpressFeeRow.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct ExpressFeeRowView: View {
    let viewModel: ExpressFeeRowData

    var isTappable: Bool { viewModel.action != nil }

    var body: some View {
        if let action = viewModel.action {
            Button(action: action) {
                content
            }
        } else {
            content
        }
    }

    private var content: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.title)
                    .style(Fonts.Regular.footnote, color: Colors.Text.secondary)

                Text(viewModel.subtitle)
                    .style(Fonts.Regular.subheadline, color: Colors.Text.primary1)
            }

            Spacer()

            if isTappable {
                Assets.chevron.image
                    .renderingMode(.template)
                    .foregroundColor(Colors.Icon.informative)
            }
        }
    }
}

#Preview("ExpressFeeRowView") {
    GroupedSection([
        ExpressFeeRowData(
            title: "Fee",
            subtitle: "0.117 MATIC (0.14 $)",
            action: {}
        ),
        ExpressFeeRowData(
            title: "Fee",
            subtitle: "0.117 MATIC (0.14 $)",
            action: nil
        ),
    ]) {
        ExpressFeeRowView(viewModel: $0)
    }
    .interSectionPadding(14)
    .interSectionPadding(12)
    .padding()
    .background(Colors.Background.secondary.ignoresSafeArea())
}
