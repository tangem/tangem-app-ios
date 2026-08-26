//
//  TangemPayActivateCardView.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

struct TangemPayActivateCardView: View {
    @ObservedObject var viewModel: TangemPayActivateCardViewModel

    var body: some View {
        cardArt
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background { DesignSystem.Color.bgPrimary.ignoresSafeArea() }
            .contentShape(Rectangle())
            .onTapGesture(perform: viewModel.focusEntry)
            .safeAreaInset(edge: .bottom, spacing: 0) { footer }
            .topNavigation(
                leading: .none,
                onClose: viewModel.close,
                content: { title }
            )
            .onDidAppear(perform: viewModel.focusEntry)
    }

    /// Static-dark rather than themed: the bar sits over the card in either app theme.
    private var title: some View {
        Text(Localization.tangempayCardDetailsActivate)
            .font(token: DesignSystem.Font.bodyMediumToken)
            .foregroundStyle(DesignSystem.Color.textStaticDarkPrimary)
            .lineLimit(1)
    }

    private var cardArt: some View {
        TangemPayActivateCardArtView(imageURL: viewModel.activationImageURL, digits: viewModel.digits)
            .background { entryField }
            .ignoresSafeArea(edges: .top)
    }

    private var entryField: some View {
        TangemPayActivateCardDigitsField(
            text: Binding(get: { viewModel.digits }, set: viewModel.updateDigits),
            isFocused: viewModel.isEntryFocused,
            maxCount: viewModel.digitCount,
            accessibilityLabel: Localization.tangempayCardActivationDescription
        )
        .opacity(0)
        .allowsHitTesting(false)
    }

    private var footer: some View {
        VStack(spacing: Constants.hintToButtonSpacing) {
            Text(viewModel.hint)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                .multilineTextAlignment(.center)

            TangemUI.Button(
                label: AttributedString(Localization.commonContinue),
                accessibilityLabel: Localization.commonContinue,
                action: viewModel.activate
            )
            .size(.x12)
            .styleType(.default)
            .horizontalLayout(.infinity)
            .isLoading(viewModel.isActivating)
            .disabled(!viewModel.isContinueEnabled)
        }
        .padding(.horizontal, Constants.footerHorizontalPadding)
        .padding(.vertical, Constants.footerVerticalPadding)
    }
}

private extension TangemPayActivateCardView {
    enum Constants {
        static let hintToButtonSpacing: CGFloat = 12
        static let footerHorizontalPadding: CGFloat = 16
        static let footerVerticalPadding: CGFloat = 12
    }
}
