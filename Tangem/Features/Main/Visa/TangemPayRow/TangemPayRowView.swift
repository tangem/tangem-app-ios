//
//  TangemPayRowView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct TangemPayRowView: View {
    let viewModel: TangemPayRowViewModel

    var body: some View {
        Button(action: viewModel.tapAction) {
            content
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var content: some View {
        HStack(spacing: 12) {
            icon

            textViews

            Spacer()

            Assets.chevron.image
        }
        .infinityFrame(axis: .horizontal, alignment: .leading)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var icon: some View {
        image
            .frame(width: 36, height: 36)
    }

    @ViewBuilder
    private var image: some View {
        Assets.Visa.card.image
            .resizable()
            .aspectRatio(contentMode: .fit)
    }

    @ViewBuilder
    private var textViews: some View {
        VStack(alignment: .leading, spacing: 2) {
            // [REDACTED_TODO_COMMENT]
            Text("Tangem Visa card")
                .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)
                .lineLimit(1)

            if viewModel.isKYCInProgress {
                // [REDACTED_TODO_COMMENT]
                Text("KYC in progress")
                    .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                    .lineLimit(1)
            }
        }
    }
}
