//
//  EarnNetworkFilterBottomSheetViewRedesign.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization

struct EarnNetworkFilterBottomSheetViewRedesign: View {
    @ObservedObject private var viewModel: EarnNetworkFilterBottomSheetViewModel

    @ScaledMetric private var contentSpacing: CGFloat = 12
    @ScaledMetric private var contentTitleTopPadding: CGFloat = 16
    @ScaledMetric private var allOptionVerticalPadding: CGFloat = 22
    @ScaledMetric private var markIconSide: CGFloat = 20
    @ScaledMetric private var footerPadding: CGFloat = 16
    @ScaledMetric private var footerButtonSpacing: CGFloat = 8

    init(viewModel: EarnNetworkFilterBottomSheetViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        EarnFilterBottomSheetLayout(
            title: viewModel.title,
            onClose: viewModel.onCloseTap,
            content: { content },
            footer: {
                if viewModel.isFooterVisible {
                    footer
                        .padding(footerPadding)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        )
        .animation(.easeInOut(duration: 0.2), value: viewModel.isFooterVisible)
    }
}

// MARK: - Subviews

private extension EarnNetworkFilterBottomSheetViewRedesign {
    var content: some View {
        VStack(spacing: contentSpacing) {
            TabNavigation(data: viewModel.scopes, selection: viewModel.scopeBinding)
                .variant(.transparent)

            GroupedSection(
                rows,
                content: { row in
                    switch row {
                    case .all:
                        allOption
                    case .network(let input):
                        EarnNetworkFilterNetworkRowViewRedesign(input: input)
                    }
                },
                header: {
                    DefaultHeaderView(Localization.earnFilterNetworks)
                        .padding(.top, contentTitleTopPadding)
                }
            )
            .separatorStyle(.none)
            .horizontalPadding(16)
            .cornerRadius(24)
            .settings(\.backgroundColor, DesignSystem.Color.bgSecondary)
        }
    }

    var rows: [Row] {
        [.all] + viewModel.networkRowInputs.map { .network($0) }
    }

    var allOption: some View {
        SwiftUI.Button(action: viewModel.onAllOptionTap) {
            HStack(spacing: .zero) {
                Text(Localization.commonAll)
                    .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)

                Spacer()

                Group {
                    if viewModel.isAllOptionSelected {
                        Assets.checkmark20.image
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(DesignSystem.Color.iconStaticDark)
                            .background(DesignSystem.Color.iconAccentBlue, in: .circle)
                    }
                }
                .frame(width: markIconSide, height: markIconSide)
            }
            .padding(.vertical, allOptionVerticalPadding)
            .contentShape(.rect)
        }
        .accessibilityAddTraits(viewModel.isAllOptionSelected ? .isSelected : [])
    }

    var footer: some View {
        VStack(spacing: footerButtonSpacing) {
            TangemUI.Button(
                label: AttributedString(Localization.commonReset),
                accessibilityLabel: Localization.commonReset,
                action: viewModel.onResetTap
            )
            .size(.x12)
            .styleType(.secondary(.default))
            .horizontalLayout(.infinity)

            TangemUI.Button(
                label: AttributedString(Localization.commonApply),
                accessibilityLabel: Localization.commonApply,
                action: viewModel.onApplyTap
            )
            .size(.x12)
            .styleType(.default)
            .horizontalLayout(.infinity)
        }
    }
}

// MARK: - Row

private extension EarnNetworkFilterBottomSheetViewRedesign {
    enum Row: Identifiable {
        case all
        case network(EarnNetworkFilterNetworkRowInput)

        var id: String {
            switch self {
            case .all:
                Constants.allRowId
            case .network(let input):
                input.id
            }
        }
    }

    enum Constants {
        static let allRowId = "all"
    }
}
