//
//  TangemPayChooseNetworkSheetView.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemPay
import TangemUI

struct TangemPayChooseNetworkSheetView: View {
    @ObservedObject var viewModel: TangemPayChooseNetworkSheetViewModel

    var body: some View {
        VStack(spacing: .zero) {
            header
                .padding(.horizontal, 16)
                .padding(.bottom, 16)

            sections
                .padding(.bottom, 16)
        }
        .floatingSheetConfiguration { configuration in
            configuration.sheetBackgroundColor = DesignSystem.Color.bgSecondary
            configuration.backgroundInteractionBehavior = .tapToDismiss
        }
    }
}

private extension TangemPayChooseNetworkSheetView {
    var header: some View {
        BottomSheetHeaderView(title: Localization.commonChooseNetwork, trailing: {
            closeButton
        })
        .titleFont(DesignSystem.Font.bodyMediumToken.font)
        .titleColor(DesignSystem.Color.textPrimary)
    }

    var closeButton: some View {
        TangemUI.Button(
            icon: DesignSystem.Icons.Cross.regular20,
            accessibilityLabel: Localization.commonClose,
            action: viewModel.close
        )
        .size(.x11)
        .styleType(.material(.glass))
    }

    var sections: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                section(title: Localization.tangempayChooseNetworkFastWay, rows: viewModel.fastWayRows)
                section(title: Localization.tangempayChooseNetworkOtherWays, rows: viewModel.otherWaysRows)
            }
        }
    }

    @ViewBuilder
    func section(title: String, rows: [TangemPayNetworkRowViewData]) -> some View {
        if !rows.isEmpty {
            VStack(spacing: .zero) {
                Text(title)
                    .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)

                ForEach(rows) { viewData in
                    networkRow(viewData)
                }
            }
        }
    }

    @ViewBuilder
    func networkRow(_ viewData: TangemPayNetworkRowViewData) -> some View {
        let content = Row(title: viewData.row.title, subtitle: viewData.subtitle)
            .titleLineLimit(1)
            .overrideTextColors(.init(subtitle: viewData.subtitleColor))
            .start {
                NetworkIcon(
                    imageAsset: viewData.row.icon,
                    isActive: false,
                    isMainIndicatorVisible: false,
                    size: CGSize(bothDimensions: 36)
                )
            }
            .end {
                rowAccessory(viewData.state)
            }

        if viewData.isTappable {
            content.onTap { viewModel.userDidTapRow(viewData) }
        } else {
            content
        }
    }

    @ViewBuilder
    func rowAccessory(_ state: TangemPayNetworkRowViewData.State) -> some View {
        switch state {
        case .idle:
            EmptyView()
        case .loading:
            Loader()
                .loaderSize(.size20)
                .loaderColor(DesignSystem.Color.iconSecondary)
        case .error:
            DesignSystem.Icons.ArrowRefresh.regular20.image
                .renderingMode(.template)
                .foregroundStyle(DesignSystem.Color.iconStatusError)
        }
    }
}
