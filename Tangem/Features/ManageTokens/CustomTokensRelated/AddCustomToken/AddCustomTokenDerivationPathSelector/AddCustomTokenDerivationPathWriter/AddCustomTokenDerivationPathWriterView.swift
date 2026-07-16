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

struct AddCustomTokenDerivationPathWriterView: View {
    @ObservedObject var viewModel: AddCustomTokenDerivationPathWriterViewModel
    private let style: Style

    /// It's strange but if we set color directly to `TextField`
    /// the color doesn't change when user is typing
    /// https://www.hackingwithswift.com/forums/100-days-of-swiftui/unusual-behavior-when-trying-to-change-the-style-of-the-text-in-a-swiftui-textfield/28414
    @State private var textFieldColor: Color = Colors.Text.primary1

    init(viewModel: AddCustomTokenDerivationPathWriterViewModel, style: Style = .legacy) {
        self.viewModel = viewModel
        self.style = style
    }

    var body: some View {
        content
            .navigationTitle(Text(Localization.customTokenCustomDerivationTitle))
            .navigationBarTitleDisplayMode(.inline)
            .alert(item: $viewModel.alert, content: { $0.alert })
            .onChange(of: viewModel.derivationPathState) { state in
                textFieldColor = state.isFailure ? Colors.Text.warning : Colors.Text.primary1
            }
    }

    @ViewBuilder
    private var content: some View {
        switch style.kind {
        case .legacy:
            legacyBody
        case .addTokenRedesigned:
            redesignedBody
        }
    }
}

// MARK: - Legacy body

private extension AddCustomTokenDerivationPathWriterView {
    /// Fills the sheet with the Save button pinned to the bottom. For the full-height
    /// page sheet, where a self-sizing stack would float in the middle of empty space.
    var legacyBody: some View {
        GroupedScrollView {
            derivationInputSection
        }
        .overlay(alignment: .bottom) {
            saveButton
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
        }
        .background(Colors.Background.tertiary.ignoresSafeArea())
    }
}

// MARK: - Redesigned body

private extension AddCustomTokenDerivationPathWriterView {
    /// Self-sizes with the Save button right under the field. For the floating sheet
    /// that hugs its content — a scroll view would collapse to zero height there.
    /// No background: the floating sheet container paints the surface, so an opaque
    /// fill here would show as a lighter block over the sheet's darker background.
    var redesignedBody: some View {
        VStack(spacing: 16) {
            derivationInputSection

            saveButton
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .top)
    }
}

// MARK: - Shared subviews

private extension AddCustomTokenDerivationPathWriterView {
    var saveButton: some View {
        MainButton(
            title: Localization.commonSave,
            isDisabled: !viewModel.derivationPathState.isSuccess,
            action: viewModel.save
        )
    }

    var derivationInputSection: some View {
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

// MARK: - Style

extension AddCustomTokenDerivationPathWriterView {
    struct Style {
        fileprivate let kind: Kind

        fileprivate enum Kind {
            case legacy
            case addTokenRedesigned
        }

        static let legacy = Style(kind: .legacy)
        static let addTokenRedesigned = Style(kind: .addTokenRedesigned)
    }
}
