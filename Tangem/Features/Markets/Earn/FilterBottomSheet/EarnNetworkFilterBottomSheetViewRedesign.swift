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

    init(viewModel: EarnNetworkFilterBottomSheetViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        EarnFilterBottomSheetLayout(
            title: viewModel.title,
            onClose: viewModel.onCloseTap,
            content: { EarnNetworkFilterContentView(viewModel: viewModel) },
            footer: { EarnNetworkFilterFooterView(viewModel: viewModel) }
        )
        .animation(.easeInOut(duration: 0.2), value: viewModel.isFooterVisible)
    }
}

struct EarnNetworkFilterContentView: View {
    @ObservedObject var viewModel: EarnNetworkFilterBottomSheetViewModel

    @ScaledMetric private var contentSpacing: CGFloat = 12
    @ScaledMetric private var contentTitleTopPadding: CGFloat = 16
    @ScaledMetric private var allOptionVerticalPadding: CGFloat = 22
    @ScaledMetric private var chipSpacing: CGFloat = 4
    @ScaledMetric private var chipHorizontalPadding: CGFloat = 12
    @ScaledMetric private var chipVerticalPadding: CGFloat = 8

    var body: some View {
        VStack(spacing: contentSpacing) {
            scopeChips

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

    private var rows: [Row] {
        [.all] + viewModel.networkRowInputs.map { .network($0) }
    }

    private var scopeChips: some View {
        HorizontalFlowLayout(
            items: viewModel.scopes,
            alignment: .leading,
            horizontalSpacing: chipSpacing,
            verticalSpacing: chipSpacing
        ) { scope in
            scopeChip(scope)
        }
    }

    private func scopeChip(_ scope: EarnNetworkFilterScope) -> some View {
        let isSelected = viewModel.selectedScope == scope

        return SwiftUI.Button(action: { viewModel.onScopeTap(scope) }) {
            Text(scope.title)
                .style(
                    DesignSystem.Font.subheadingMediumToken,
                    color: isSelected ? DesignSystem.Color.textInversePrimary : DesignSystem.Color.textPrimary
                )
                .lineLimit(1)
                .padding(.horizontal, chipHorizontalPadding)
                .padding(.vertical, chipVerticalPadding)
                .background(
                    isSelected ? DesignSystem.Color.bgInverse : DesignSystem.Color.bgTransparentPrimary,
                    in: .capsule
                )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var allOption: some View {
        SwiftUI.Button(action: viewModel.onAllOptionTap) {
            HStack(spacing: .zero) {
                Text(Localization.commonAll)
                    .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)

                Spacer()

                TangemUI.Checkmark(checked: viewModel.isAllOptionSelected, action: {})
                    .expandsHitArea(false)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
            .padding(.vertical, allOptionVerticalPadding)
            .contentShape(.rect)
        }
        .accessibilityAddTraits(viewModel.isAllOptionSelected ? .isSelected : [])
    }
}

struct EarnNetworkFilterFooterView: View {
    @ObservedObject var viewModel: EarnNetworkFilterBottomSheetViewModel

    var body: some View {
        FilterFooterView(
            isVisible: viewModel.isFooterVisible,
            onReset: viewModel.onResetTap,
            onApply: viewModel.onApplyTap
        )
    }
}

// MARK: - Row

private extension EarnNetworkFilterContentView {
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
