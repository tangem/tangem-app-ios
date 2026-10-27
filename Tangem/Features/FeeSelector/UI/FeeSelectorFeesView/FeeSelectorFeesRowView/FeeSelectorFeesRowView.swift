//
//  FeeSelectorFeesRowView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemAccessibilityIdentifiers
import TangemUIUtils

struct FeeSelectorFeesRowView: SelectableSectionRow {
    private let viewModel: FeeSelectorFeesRowViewModel
    @Binding var isSelected: Bool

    var shouldShowCustomFeeFields: Bool {
        viewModel.fee.option == .custom && isSelected
    }

    init(viewModel: FeeSelectorFeesRowViewModel, isSelected: Binding<Bool>) {
        self.viewModel = viewModel
        _isSelected = isSelected
    }

    var body: some View {
        VStack(alignment: .center, spacing: .zero) {
            mainContent

            customFeeFields
        }
        .background(backgroundView)
    }

    private var mainContent: some View {
        SwiftUI.Button(action: { isSelected = true }) {
            HStack(alignment: .center, spacing: 12) {
                icon

                content

                Spacer()
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 14)
        }
        .accessibilityIdentifier(viewModel.fee.option.accessibilityIdentifier)
    }

    private var icon: some View {
        ZStack(alignment: .center) {
            RoundedRectangle(cornerRadius: 36 / 2)
                .fill(isSelected ? DesignSystem.Color.bgAccentBlueSubtle : DesignSystem.Color.bgTransparentPrimary)
                .frame(width: 36, height: 36)

            viewModel.fee.option.icon.image
                .resizable()
                .renderingMode(.template)
                .foregroundStyle(isSelected ? DesignSystem.Color.iconAccentBlue : DesignSystem.Color.iconSecondary)
                .frame(width: 24, height: 24)
        }
        .accessibilityIdentifier(isSelected ? FeeAccessibilityIdentifiers.feeOptionSelectedIndicator : nil)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(viewModel.fee.option.title)
                .style(Fonts.Bold.subheadline, color: DesignSystem.Color.textPrimary)
                .multilineTextAlignment(.leading)

            Text(viewModel.feeComponents.formatted)
                .style(Fonts.Regular.caption1, color: DesignSystem.Color.textSecondary)
        }
    }

    @ViewBuilder
    private var customFeeFields: some View {
        if shouldShowCustomFeeFields {
            VStack(alignment: .leading, spacing: 14) {
                ForEach(viewModel.customFields) { customFieldViewModel in
                    FeeSelectorCustomFeeRowView(viewModel: customFieldViewModel)

                    if customFieldViewModel.id != viewModel.customFields.last?.id {
                        Separator(color: DesignSystem.Color.borderSecondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .transition(.opacity.animation(.default))
        }
    }

    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(DesignSystem.Color.bgSecondary)
    }
}
