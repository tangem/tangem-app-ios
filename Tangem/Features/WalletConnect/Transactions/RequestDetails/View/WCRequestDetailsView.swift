//
//  WCRequestDetailsView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils
import TangemUI
import TangemLocalization

struct WCRequestDetailsView: View {
    private let viewModel: WCRequestDetailsViewModel

    init(input: WCRequestDetailsInput) {
        viewModel = .init(input: input)
    }

    var body: some View {
        requestDataContent
    }

    private var requestDataContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(viewModel.requestDetails, content: requestDataSection)
                    .padding(.horizontal, 16)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }

    private func requestDataSection(_ section: WCTransactionDetailsSection) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            if let sectionTitle = section.sectionTitle {
                Text(sectionTitle)
                    .style(Fonts.Bold.footnote, color: DesignSystem.Color.textSecondary)
                    .padding(.bottom, 14)
            }

            ForEach(section.items) {
                requestDataSectionItem($0)
                    .padding(.bottom, $0 == section.items.last ? 10 : 20)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.init(top: 12, leading: 16, bottom: 14, trailing: 16))
        .background(DesignSystem.Color.bgSecondary)
        .cornerRadius(14, corners: .allCorners)
        .multilineTextAlignment(.leading)
    }

    private func requestDataSectionItem(_ item: WCTransactionDetailsSection.WCTransactionDetailsItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(item.title)
                .style(Fonts.Regular.footnote, color: DesignSystem.Color.textSecondary)

            Text(item.value)
                .style(Fonts.Regular.callout, color: DesignSystem.Color.textPrimary)
        }
        .frame(maxHeight: .infinity)
    }
}
