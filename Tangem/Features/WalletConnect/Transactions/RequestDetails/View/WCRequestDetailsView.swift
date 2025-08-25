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
    @StateObject private var viewModel: WCRequestDetailsViewModel

    @State private var contentHeight: CGFloat = 0
    @State private var containerHeight: CGFloat = 0

    init(input: WCRequestDetailsInput) {
        _viewModel = .init(wrappedValue: .init(input: input))
    }

    var body: some View {
        requestDataContent
    }

    private var requestDataContent: some View {
        ZStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 12) {
                requestDataHeader

                ScrollView(showsIndicators: false) {
                    ForEach(viewModel.requestDetails) {
                        requestDataSection($0)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, viewModel.isCopyButtonVisible ? 80 : 16)
                }
                .scrollBounceBehaviorBackport(.basedOnSize)
            }
            copyButton
        }
    }

    private func requestDataSection(_ section: WCTransactionDetailsSection) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            if let sectionTitle = section.sectionTitle {
                Text(sectionTitle)
                    .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
                    .padding(.bottom, 14)
            }

            ForEach(section.items) {
                requestDataSectionItem($0)
                    .padding(.bottom, $0 == section.items.last ? 10 : 20)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.init(top: 12, leading: 16, bottom: 14, trailing: 16))
        .background(Colors.Background.action)
        .cornerRadius(14, corners: .allCorners)
        .multilineTextAlignment(.leading)
    }

    private func requestDataSectionItem(_ item: WCTransactionDetailsSection.WCTransactionDetailsItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(item.title)
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)

            Text(item.value)
                .style(Fonts.Regular.callout, color: Colors.Text.primary1)
        }
    }

    private var requestDataHeader: some View {
        WalletConnectNavigationBarView(
            title: Localization.wcTransactionRequestTitle,
            backButtonAction: { viewModel.handleViewAction(.returnTransactionDetails) }
        )
    }

    @ViewBuilder
    private var copyButton: some View {
        MainButton(
            title: Localization.wcCopyDataButtonText,
            icon: .trailing(Assets.Glyphs.copy),
            style: .primary,
            size: .default,
            action: {
                viewModel.handleViewAction(.copy)
            }
        )
        .padding(16)
    }
}
