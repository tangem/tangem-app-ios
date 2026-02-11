//
//  FeeSelectorFeesView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization
import TangemAccessibilityIdentifiers

struct FeeSelectorFeesView: View {
    @ObservedObject var viewModel: FeeSelectorFeesViewModel
    let customFeeManualSaveButtonSettings: CustomFeeManualSaveButtonSettings?

    init(
        viewModel: FeeSelectorFeesViewModel,
        customFeeManualSaveButtonSettings: CustomFeeManualSaveButtonSettings? = .init()
    ) {
        self.viewModel = viewModel
        self.customFeeManualSaveButtonSettings = customFeeManualSaveButtonSettings
    }

    var body: some View {
        VStack(spacing: .zero) {
            content

            if let customFeeManualSaveButtonSettings, viewModel.customFeeManualSaveIsRequired {
                footer(settings: customFeeManualSaveButtonSettings)
            }
        }
        .onAppear(perform: viewModel.onAppear)
    }

    var content: some View {
        ScrollView {
            SelectableSection(viewModel.rowViewModels) { data in
                FeeSelectorFeesRowView(
                    viewModel: data,
                    isSelected: viewModel.isSelected(data.fee).asBinding
                )
            }
            // Should start where title starts (14 + 36 + 12)
            .separatorPadding(.init(leading: 62, trailing: 14))
            .enableSeparators(false)
            .padding(.horizontal, 14)
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollIndicators(.hidden)
        .padding(.bottom, 16)
    }

    func footer(settings: CustomFeeManualSaveButtonSettings) -> some View {
        MainButton(
            title: settings.title,
            isDisabled: !viewModel.customFeeManualSaveIsAvailable,
            action: viewModel.userDidTapCustomFeeManualSaveButton
        )
        .padding(.bottom, 16)
        .padding(.horizontal, 16)
        .accessibilityIdentifier(FeeAccessibilityIdentifiers.feeSelectorDoneButton)
    }
}

extension FeeSelectorFeesView {
    typealias CustomFeeManualSaveButtonSettings = FeeSelectorView.CustomFeeManualSaveButtonSettings
}
