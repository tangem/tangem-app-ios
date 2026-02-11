//
//  CloreMigrationView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemLocalization

struct CloreMigrationView: View {
    @ObservedObject var viewModel: CloreMigrationViewModel

    var body: some View {
        rootView
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            .safeAreaInset(edge: .top, spacing: .zero) {
                header
            }
    }

    private var header: some View {
        return FloatingSheetNavigationBarView(
            title: nil,
            backButtonAction: nil,
            closeButtonAction: viewModel.onCloseTap
        )
    }

    private var rootView: some View {
        VStack(spacing: 24) {
            texts
            fields
            button
        }
    }

    private var texts: some View {
        VStack(spacing: 8) {
            Text(Localization.warningCloreMigrationSheetTitle)
                .style(Fonts.Bold.title2, color: Colors.Text.primary1)
                .multilineTextAlignment(.center)

            Text(Localization.warningCloreMigrationSheetDescription)
                .style(Fonts.Regular.subheadline, color: Colors.Text.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var fields: some View {
        VStack(spacing: 12) {
            HStack {
                CustomTextField(
                    text: $viewModel.message,
                    isResponder: .constant(false),
                    actionButtonTapped: .constant(true),
                    handleKeyboard: false,
                    keyboard: .default,
                    clearButtonMode: .whileEditing,
                    placeholder: Localization.warningCloreMigrationMessageLabel
                )

                signButton
            }
            .frame(height: 32)
            .defaultRoundedBackground(with: Colors.Background.action)

            HStack {
                CustomTextField(
                    text: $viewModel.signature,
                    isResponder: .constant(false),
                    actionButtonTapped: .constant(true),
                    handleKeyboard: false,
                    keyboard: .default,
                    clearButtonMode: .never,
                    placeholder: Localization.warningCloreMigrationSignatureLabel,
                    isEnabled: false
                )

                copyButton
            }
            .frame(height: 32)
            .defaultRoundedBackground(with: Colors.Background.action)
        }
    }

    private var button: some View {
        MainButton(
            title: Localization.warningCloreMigrationOpenPortalButton,
            action: {
                viewModel.openCloreMigrationPortal()
            }
        )
    }

    private var signButton: some View {
        CapsuleButton(title: Localization.warningCloreMigrationSignButton) {
            viewModel.sign()
        }
        .disabled(viewModel.message.isEmpty)
    }

    private var copyButton: some View {
        CapsuleButton(title: Localization.warningCloreMigrationCopyButton) {
            viewModel.copySignature()
        }
        .disabled(viewModel.signature.isEmpty)
    }
}
