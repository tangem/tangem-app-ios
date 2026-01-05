//
//  FeeSelectorContentView.swift
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

struct FeeSelectorContentView: View {
    @ObservedObject var viewModel: FeeSelectorContentViewModel

    let headerSettings: HeaderSettings?
    let customFeeManualSaveButtonSettings: CustomFeeManualSaveButtonSettings?

    init(
        viewModel: FeeSelectorContentViewModel,
        headerSettings: HeaderSettings? = .init(),
        customFeeManualSaveButtonSettings: CustomFeeManualSaveButtonSettings? = .init()
    ) {
        self.viewModel = viewModel
        self.headerSettings = headerSettings
        self.customFeeManualSaveButtonSettings = customFeeManualSaveButtonSettings
    }

    var body: some View {
        VStack(spacing: .zero) {
            if let headerSettings {
                header(settings: headerSettings)
            }

            content

            if let customFeeManualSaveButtonSettings, viewModel.customFeeManualSaveIsRequired {
                footer(settings: customFeeManualSaveButtonSettings)
            }
        }
        .padding(.bottom, 16)
        .onAppear(perform: viewModel.onAppear)
        .floatingSheetConfiguration { configuration in
            configuration.sheetBackgroundColor = Colors.Background.action
            configuration.sheetFrameUpdateAnimation = .easeInOut
            configuration.backgroundInteractionBehavior = .tapToDismiss
        }
    }

    var content: some View {
        ScrollView {
            SelectableSection(viewModel.rowViewModels) { data in
                FeeSelectorContentRowView(
                    viewModel: data,
                    isSelected: viewModel.isSelected(data.fee).asBinding
                )
            }
            // Should start where title starts (14 + 36 + 12)
            .separatorPadding(.init(leading: 62, trailing: 14))
            .padding(.horizontal, 14)
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollIndicators(.hidden)
    }

    func header(settings: HeaderSettings) -> some View {
        BottomSheetHeaderView(
            title: settings.title,
            leading: {
                if case .back = settings.dismissType {
                    CircleButton.back(action: viewModel.userDidTapDismissButton)
                }
            },
            trailing: {
                if case .close = settings.dismissType {
                    CircleButton.close(action: viewModel.userDidTapDismissButton)
                }
            }
        )
        .padding(.vertical, 4)
        .padding(.horizontal, 16)
    }

    func footer(settings: CustomFeeManualSaveButtonSettings) -> some View {
        MainButton(
            title: settings.title,
            isDisabled: viewModel.customFeeManualSaveIsRequired,
            action: viewModel.userDidTapCustomFeeManualSaveButton
        )
        .padding(.bottom, 16)
        .padding(.horizontal, 16)
        .accessibilityIdentifier(FeeAccessibilityIdentifiers.feeSelectorDoneButton)
    }
}

extension FeeSelectorContentView {
    struct HeaderSettings {
        let title: String
        let dismissType: FeeSelectorDismissButtonType

        init(
            title: String = Localization.commonNetworkFeeTitle,
            dismissType: FeeSelectorDismissButtonType = .close
        ) {
            self.title = title
            self.dismissType = dismissType
        }
    }

    struct CustomFeeManualSaveButtonSettings {
        let title: String

        init(title: String = Localization.commonDone) {
            self.title = title
        }
    }
}
