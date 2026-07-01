//
//  AddCustomTokenDerivationPathWriterView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI
import TangemAccessibilityIdentifiers

struct AddCustomTokenDerivationPathWriterView: View {
    @ObservedObject var viewModel: AddCustomTokenDerivationPathWriterViewModel

    /// It's strange but if we set color directly to `TextField`
    /// the color doesn't change when user is typing
    /// https://www.hackingwithswift.com/forums/100-days-of-swiftui/unusual-behavior-when-trying-to-change-the-style-of-the-text-in-a-swiftui-textfield/28414
    @State private var textFieldColor: Color = Colors.Text.primary1

    var body: some View {
        VStack(spacing: 16) {
            derivationInputSection

            MainButton(
                title: Localization.commonSave,
                isDisabled: !viewModel.derivationPathState.isSuccess,
                accessibilityIdentifier: AddCustomTokenAccessibilityIdentifiers.derivationPathSaveButton,
                action: viewModel.save
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(Colors.Background.tertiary.ignoresSafeArea())
        .navigationTitle(Text(Localization.customTokenCustomDerivationTitle))
        .navigationBarTitleDisplayMode(.inline)
        .alert(item: $viewModel.alert, content: { $0.alert })
        .onChange(of: viewModel.derivationPathState) { state in
            textFieldColor = state.isFailure ? Colors.Text.warning : Colors.Text.primary1
        }
    }

    private var derivationInputSection: some View {
        GroupedSection(viewModel) { _ in
            TextField(text: $viewModel.derivationPathText) {
                Text(Localization.customTokenCustomDerivationPlaceholder)
                    .style(Fonts.Regular.subheadline, color: Colors.Text.disabled)
            }
            .font(Fonts.Regular.subheadline)
            .foregroundStyle(textFieldColor)
            .tint(textFieldColor)
            .autocapitalization(.none)
            .disableAutocorrection(true)
            .accessibilityIdentifier(AddCustomTokenAccessibilityIdentifiers.derivationPathField)
        } header: {
            Text(Localization.customTokenCustomDerivation)
                .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
        } footer: {
            if case .failure(.some(let hint)) = viewModel.derivationPathState {
                Text(hint)
                    .style(Fonts.Regular.footnote, color: Colors.Text.warning)
            }
        }
        .innerContentPadding(12)
        .interItemSpacing(4)
        .backgroundColor(Colors.Background.action)
    }
}
