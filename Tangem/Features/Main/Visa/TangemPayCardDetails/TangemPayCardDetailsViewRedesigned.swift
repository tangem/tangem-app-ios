//
//  TangemPayCardDetailsViewRedesigned.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import Kingfisher
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils
import TangemAccessibilityIdentifiers

struct TangemPayCardDetailsViewRedesigned: View {
    @ObservedObject var viewModel: TangemPayCardDetailsViewModel

    var showsInlineDetailsButton: Bool = false

    @FocusState private var isCardNameFocused: Bool
    @State private var animationProgress: CGFloat = .zero
    @State private var onHalfFlipCalled: Bool = false

    var body: some View {
        Group {
            switch viewModel.state {
            case .loaded(let state):
                switch state {
                case .revealed(let data):
                    loadedStateContent(cardDetails: data)
                case .unrevealed(let data, let isLoading):
                    loadedStateContent(cardDetails: data, isLoading: isLoading)
                }
            case .hidden:
                hiddenStateContent(isLoading: false)
            case .loading:
                hiddenStateContent(isLoading: true)
            case .issuing:
                issuingStateContent()
            }
        }
        .padding(20)
        .background(cardBackground)
        .overlay {
            if viewModel.state.isFrozen {
                Assets.Visa.cardFrost.image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .aspectRatio(Constants.plasticCardStandardWidthToHeightRatio, contentMode: .fit)
        .background(
            DesignSystem.Color.bgPrimary,
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                .allowsHitTesting(false)
        }
        .onAnimationTargetProgress(
            for: animationProgress,
            targetValue: 0.45,
            comparator: { lhs, rhs in
                if viewModel.isFlipped {
                    return lhs >= rhs
                } else {
                    return lhs <= (1 - rhs)
                }
            }
        ) {
            guard !onHalfFlipCalled else { return }
            onHalfFlipCalled = true
            viewModel.changeStateIfNeeded()
        }
        .onAnimationCompleted(for: animationProgress) {
            onHalfFlipCalled = false
        }
        .flipAnimation(progress: animationProgress)
        .onChange(of: viewModel.isFlipped) { isFlipped in
            animationProgress = isFlipped ? 1 : .zero
        }
        .animation(
            .easeInOut(duration: 0.6).speed(0.75),
            value: animationProgress
        )
    }

    private func issuingStateContent() -> some View {
        VStack {
            cardHeader
            Spacer()
        }
    }

    private func hiddenStateContent(isLoading: Bool) -> some View {
        VStack {
            cardHeader

            Spacer()

            HStack(alignment: .bottom, spacing: 6) {
                VStack(alignment: .leading, spacing: 2) {
                    cardNameContent()

                    HStack(spacing: 6) {
                        Text("*" + viewModel.lastFourDigits)
                            .font(token: DesignSystem.Font.bodyMediumToken)
                            .foregroundStyle(
                                viewModel.cardNameDisplayMode == .editing
                                    ? DesignSystem.Color.textStaticDarkSecondary
                                    : DesignSystem.Color.textStaticDarkPrimary
                            )

                        Group {
                            if isLoading {
                                CircularActivityIndicator(color: .white, lineWidth: 1.5)
                            }
                        }
                        .frame(width: 16, height: 16)
                    }
                }

                Spacer()

                if showsInlineDetailsButton, viewModel.state.showDetailsButtonVisible {
                    showDetailsButton
                }
            }
        }
    }

    private func loadedStateContent(
        cardDetails: TangemPayCardDetailsData,
        isLoading: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                cardDetailField(
                    label: Localization.tangempayCardDetailsCardNumber,
                    value: cardDetails.number,
                    valueAccessibilityIdentifier: TangemPayAccessibilityIdentifiers.cardDetailsNumberValue,
                    copyAccessibilityIdentifier: TangemPayAccessibilityIdentifiers.cardDetailsCopyNumber,
                    copyAction: viewModel.copyNumber
                )

                fieldSeparator

                if !cardDetails.cardholderName.isEmpty {
                    cardDetailField(
                        label: Localization.tangempayCardDetailsNameOnCard,
                        value: cardDetails.cardholderName,
                        valueAccessibilityIdentifier: TangemPayAccessibilityIdentifiers.cardDetailsCardholderNameValue,
                        copyAccessibilityIdentifier: TangemPayAccessibilityIdentifiers.cardDetailsCopyCardholderName,
                        copyAction: viewModel.copyCardholderName
                    )

                    fieldSeparator
                }

                HStack(spacing: 12) {
                    cardDetailField(
                        label: Localization.tangempayCardDetailsExpiry,
                        value: cardDetails.expirationDate,
                        valueWidth: Constants.compactValueWidth,
                        valueAccessibilityIdentifier: TangemPayAccessibilityIdentifiers.cardDetailsExpirationValue,
                        copyAccessibilityIdentifier: TangemPayAccessibilityIdentifiers.cardDetailsCopyExpiration,
                        copyAction: viewModel.copyExpirationDate
                    )

                    Divider()
                        .overlay(Constants.separatorColor)

                    cardDetailField(
                        label: Localization.tangempayCardDetailsCvc,
                        value: cardDetails.cvc,
                        valueWidth: Constants.compactValueWidth,
                        valueAccessibilityIdentifier: TangemPayAccessibilityIdentifiers.cardDetailsCvcValue,
                        copyAccessibilityIdentifier: TangemPayAccessibilityIdentifiers.cardDetailsCopyCvc,
                        copyAction: viewModel.copyCVC
                    )

                    Spacer()
                }
            }

            Spacer()

            HStack(alignment: .bottom) {
                if isLoading {
                    CircularActivityIndicator(color: .white, lineWidth: 1.5)
                        .frame(width: 16, height: 16)
                }

                Spacer()

                closeButton
            }
        }
        .screenCaptureProtection()
    }

    private var fieldSeparator: some View {
        Separator(color: Constants.separatorColor)
    }

    private var showDetailsButton: some View {
        Button(action: viewModel.toggleVisibility) {
            Text(Localization.tangempayCardDetailsShowDetails)
                .font(token: DesignSystem.Font.bodyMediumToken)
                .foregroundStyle(DesignSystem.Color.textStaticDarkPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(DesignSystem.Color.bgOpaquePrimary, in: Capsule())
        }
        .accessibilityIdentifier(TangemPayAccessibilityIdentifiers.cardDetailsShowButton)
    }

    private var closeButton: some View {
        TangemUI.Button(
            label: Localization.commonClose,
            accessibilityLabel: Localization.tangempayCardDetailsHideDetails,
            action: viewModel.toggleVisibility
        )
        .size(.x8)
        .styleType(.secondary)
        .accessibilityIdentifier(TangemPayAccessibilityIdentifiers.cardDetailsHideButton)
        .environment(\.colorScheme, .dark)
    }

    private var cardHeader: some View {
        HStack(alignment: .center, spacing: 6) {
            Text(Localization.tangempayDigitalCard)
                .font(token: DesignSystem.Font.bodyMediumToken)
                .foregroundStyle(DesignSystem.Color.textStaticDarkPrimary)

            DesignSystem.Icons.Cloud.filled20.image
                .renderingMode(.template)
                .foregroundStyle(DesignSystem.Color.iconStaticDark)

            Spacer()
        }
    }

    private var cardBackground: some View {
        switch viewModel.state {
        case .loaded:
            KFImage(viewModel.cardBackgroundImageURL)
                .resizable()
        case .hidden, .loading, .issuing:
            KFImage(viewModel.cardImageURL)
                .placeholder {
                    Assets.Visa.cardGhost.image
                        .resizable()
                }
                .resizable()
        }
    }

    @ViewBuilder
    private func cardNameContent() -> some View {
        switch viewModel.cardNameDisplayMode {
        case .display:
            Text(viewModel.cardName)
                .font(token: DesignSystem.Font.bodyMediumToken)
                .foregroundStyle(DesignSystem.Color.textStaticDarkSecondary)
        case .interactive:
            Button(action: viewModel.cardNameTapped) {
                HStack(spacing: 4) {
                    Text(viewModel.cardName)
                        .font(token: DesignSystem.Font.bodyMediumToken)
                        .foregroundStyle(DesignSystem.Color.textStaticDarkSecondary)

                    DesignSystem.Icons.Edit.regular20.image
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 20, height: 20)
                        .foregroundStyle(DesignSystem.Color.textStaticDarkPrimary)
                }
            }
            .accessibilityIdentifier(TangemPayAccessibilityIdentifiers.cardNameEditButton)
        case .editing:
            TextField(
                text: $viewModel.cardName,
                label: {
                    Text(Localization.tangempayCardDetailsRenameCardPlaceholder)
                        .font(token: DesignSystem.Font.bodyMediumToken)
                        .foregroundStyle(DesignSystem.Color.textStaticDarkTertiary)
                }
            )
            .font(token: DesignSystem.Font.bodyMediumToken)
            .foregroundStyle(DesignSystem.Color.textStaticDarkPrimary)
            .tint(DesignSystem.Color.textStaticDarkPrimary)
            .accessibilityIdentifier(TangemPayAccessibilityIdentifiers.cardNameTextField)
            .focused($isCardNameFocused)
            .disabled(viewModel.isCardNameEditingDisabled)
            .task {
                try? await Task.sleep(for: .milliseconds(300))
                isCardNameFocused = true
            }
        }
    }

    private func cardDetailField(
        label: String,
        value: String,
        valueWidth: CGFloat? = nil,
        valueAccessibilityIdentifier: String,
        copyAccessibilityIdentifier: String,
        copyAction: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textStaticDarkSecondary)

            HStack(spacing: 4) {
                Text(value)
                    .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textStaticDarkPrimary)
                    .frame(minWidth: valueWidth, maxWidth: valueWidth ?? .infinity, alignment: .leading)
                    .accessibilityIdentifier(valueAccessibilityIdentifier)

                Button(action: copyAction) {
                    DesignSystem.Icons.Copy.regular16.image
                        .renderingMode(.template)
                        .foregroundStyle(DesignSystem.Color.iconStaticDark)
                }
                .accessibilityIdentifier(copyAccessibilityIdentifier)
            }
        }
    }
}

private extension TangemPayCardDetailsViewRedesigned {
    enum Constants {
        static let plasticCardStandardWidthToHeightRatio = 1.586
        static let separatorColor = Color.white.opacity(0.1)
        static let compactValueWidth: CGFloat = 56
    }
}

// MARK: - CircularActivityIndicator

private struct CircularActivityIndicator: View {
    let color: Color
    let lineWidth: CGFloat

    @State private var isAnimating = false

    var body: some View {
        Circle()
            .trim(from: 0, to: 0.7)
            .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
            .animation(
                Animation.linear(duration: 1)
                    .repeatForever(autoreverses: false),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}
