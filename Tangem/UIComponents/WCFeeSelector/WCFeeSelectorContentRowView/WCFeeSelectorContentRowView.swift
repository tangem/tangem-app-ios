//
//  WCFeeSelectorContentRowView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets

struct WCFeeSelectorContentRowView: SelectableSectionRow {
    private let viewModel: WCFeeSelectorContentRowViewModel
    @Binding var isSelected: Bool

    var shouldShowCustomFeeFields: Bool {
        viewModel.feeOption == .custom && isSelected
    }

    init(viewModel: WCFeeSelectorContentRowViewModel, isSelected: Binding<Bool>) {
        self.viewModel = viewModel
        _isSelected = isSelected
    }

    var body: some View {
        VStack(alignment: .center, spacing: .zero) {
            mainContent

            customFeeFields
        }
    }

    private var mainContent: some View {
        Button(action: { isSelected = true }) {
            HStack(alignment: .center, spacing: 12) {
                icon

                content

                Spacer()
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 14)
        }
        .accessibilityIdentifier(viewModel.feeOption.accessibilityIdentifier)
    }

    private var icon: some View {
        ZStack(alignment: .center) {
            RoundedRectangle(cornerRadius: 36 / 2)
                .fill(isSelected ? Colors.Icon.accent.opacity(0.1) : Colors.Background.tertiary)
                .frame(width: 36, height: 36)

            viewModel.feeOption.icon.image
                .resizable()
                .renderingMode(.template)
                .foregroundStyle(isSelected ? Colors.Icon.accent : Colors.Text.tertiary)
                .frame(width: 24, height: 24)
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(viewModel.feeOption.title)
                .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)
                .multilineTextAlignment(.leading)

            Text(viewModel.feeComponents.formatted)
                .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
        }
    }

    @ViewBuilder
    private var customFeeFields: some View {
        if shouldShowCustomFeeFields {
            VStack(alignment: .leading, spacing: 14) {
                ForEach(viewModel.customFields) { customFieldViewModel in
                    FeeSelectorCustomFeeRowView(viewModel: customFieldViewModel)

                    if customFieldViewModel.id != viewModel.customFields.last?.id {
                        Separator(color: Colors.Stroke.primary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .transition(.opacity.animation(.default))
        }
    }
}
