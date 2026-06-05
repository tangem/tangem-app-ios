//
//  TangemPayCardDetailsViewRedesigned.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUIUtils
import TangemAccessibilityIdentifiers

struct TangemPayCardDetailsViewRedesigned: View {
    @ObservedObject var viewModel: TangemPayCardDetailsViewModel

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
            case .hidden(let isFrozen):
                hiddenStateContent(isFrozen: isFrozen, isLoading: false)
            case .loading(let isFrozen):
                hiddenStateContent(isFrozen: isFrozen, isLoading: true)
            case .issuing:
                issuingStateContent()
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Tokens.CornerRadius._250, style: .continuous))
        .aspectRatio(Constants.plasticCardStandardWidthToHeightRatio, contentMode: .fit)
        .background(
            Color.Tangem.Visa.cardDetailBackground,
            in: RoundedRectangle(cornerRadius: DesignSystem.Tokens.CornerRadius._250, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: DesignSystem.Tokens.CornerRadius._250, style: .continuous)
                .strokeBorder(Color.white.opacity(0.1), lineWidth: DesignSystem.Tokens.BorderWidth.sm)
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
        .padding(DesignSystem.Tokens.Spacing.s200)
        .background(cardArtBackground)
    }

    private func hiddenStateContent(isFrozen: Bool, isLoading: Bool) -> some View {
        VStack {
            cardHeader

            Spacer()

            HStack(alignment: .bottom, spacing: DesignSystem.Tokens.Spacing.s075) {
                VStack(alignment: .leading, spacing: DesignSystem.Tokens.Spacing.s025) {
                    cardNameContent()

                    HStack(spacing: DesignSystem.Tokens.Spacing.s075) {
                        Text("*" + viewModel.lastFourDigits)
                            .font(DesignSystem.Tokens.Font.Body.medium)
                            .foregroundStyle(DesignSystem.Tokens.Theme.Text.StaticDark.primary)

                        Group {
                            if isLoading {
                                CircularActivityIndicator(color: .white, lineWidth: 1.5)
                            } else if isFrozen {
                                Image(systemName: "snowflake")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .foregroundStyle(DesignSystem.Tokens.Theme.Text.StaticDark.primary)
                            }
                        }
                        .frame(width: DesignSystem.Tokens.Size.s200, height: DesignSystem.Tokens.Size.s200)
                    }
                }

                Spacer()
            }
        }
        .padding(DesignSystem.Tokens.Spacing.s200)
        .background(cardArtBackground)
        .overlay {
            if isFrozen {
                Assets.Visa.cardFrost.image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }
        }
    }

    private func loadedStateContent(
        cardDetails: TangemPayCardDetailsData,
        isLoading: Bool = false
    ) -> some View {
        VStack {
            VStack(spacing: DesignSystem.Tokens.Spacing.s150) {
                cardDetailField(
                    label: Localization.tangempayCardDetailsCardNumber,
                    value: cardDetails.number,
                    valueAccessibilityIdentifier: TangemPayAccessibilityIdentifiers.cardDetailsNumberValue,
                    copyAccessibilityIdentifier: TangemPayAccessibilityIdentifiers.cardDetailsCopyNumber,
                    copyAction: viewModel.copyNumber
                )

                HStack(spacing: DesignSystem.Tokens.Spacing.s150) {
                    cardDetailField(
                        label: Localization.tangempayCardDetailsExpiry,
                        value: cardDetails.expirationDate,
                        valueAccessibilityIdentifier: TangemPayAccessibilityIdentifiers.cardDetailsExpirationValue,
                        copyAccessibilityIdentifier: TangemPayAccessibilityIdentifiers.cardDetailsCopyExpiration,
                        copyAction: viewModel.copyExpirationDate
                    )

                    cardDetailField(
                        label: Localization.tangempayCardDetailsCvc,
                        value: cardDetails.cvc,
                        valueAccessibilityIdentifier: TangemPayAccessibilityIdentifiers.cardDetailsCvcValue,
                        copyAccessibilityIdentifier: TangemPayAccessibilityIdentifiers.cardDetailsCopyCvc,
                        copyAction: viewModel.copyCVC
                    )
                }
            }

            Spacer()

            HStack(alignment: .bottom) {
                if isLoading {
                    CircularActivityIndicator(color: .white, lineWidth: 1.5)
                        .frame(width: DesignSystem.Tokens.Size.s200, height: DesignSystem.Tokens.Size.s200)
                }

                Spacer()

                closeButton
            }
        }
        .padding(DesignSystem.Tokens.Spacing.s200)
        .background {
            Assets.Visa.cardCredentials.image
                .resizable()
        }
        .screenCaptureProtection()
    }

    private var closeButton: some View {
        Button(action: viewModel.toggleVisibility) {
            DesignSystem.Icons.Cross.regular20.image
                .renderingMode(.template)
                .resizable()
                .frame(width: DesignSystem.Tokens.Size.s250, height: DesignSystem.Tokens.Size.s250)
                .foregroundStyle(DesignSystem.Tokens.Theme.Text.StaticDark.primary)
                .padding(DesignSystem.Tokens.Spacing.s075)
                .background(DesignSystem.Tokens.Theme.Bg.Opaque.primary, in: Circle())
        }
    }

    private var cardHeader: some View {
        HStack(alignment: .center, spacing: DesignSystem.Tokens.Spacing.s075) {
            Image(systemName: "cloud.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 10)
                .foregroundStyle(DesignSystem.Tokens.Theme.Text.StaticDark.primary)

            Text(Localization.tangempayDigitalCard)
                .font(DesignSystem.Tokens.Font.Body.medium)
                .foregroundStyle(DesignSystem.Tokens.Theme.Text.StaticDark.primary)

            Spacer()
        }
        .padding(.top, DesignSystem.Tokens.Spacing.s050)
    }

    private var cardArtBackground: some View {
        Assets.Visa.cardPlatinum.image
            .resizable()
    }

    @ViewBuilder
    private func cardNameContent() -> some View {
        switch viewModel.cardNameDisplayMode {
        case .display:
            Text(viewModel.cardName)
                .font(DesignSystem.Tokens.Font.Body.medium)
                .foregroundStyle(DesignSystem.Tokens.Theme.Text.StaticDark.secondary)
        case .interactive:
            Button(action: viewModel.cardNameTapped) {
                HStack(spacing: DesignSystem.Tokens.Spacing.s050) {
                    Text(viewModel.cardName)
                        .font(DesignSystem.Tokens.Font.Body.medium)
                        .foregroundStyle(DesignSystem.Tokens.Theme.Text.StaticDark.secondary)

                    DesignSystem.Icons.Edit.regular20.image
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: DesignSystem.Tokens.Size.s250, height: DesignSystem.Tokens.Size.s250)
                        .foregroundStyle(DesignSystem.Tokens.Theme.Text.StaticDark.primary)
                }
            }
        case .editing:
            TextField(
                text: $viewModel.cardName,
                label: {
                    Text(Localization.tangempayCardDetailsRenameCardPlaceholder)
                        .font(DesignSystem.Tokens.Font.Body.medium)
                        .foregroundStyle(DesignSystem.Tokens.Theme.Text.StaticDark.tertiary)
                }
            )
            .font(DesignSystem.Tokens.Font.Body.medium)
            .foregroundStyle(DesignSystem.Tokens.Theme.Text.StaticDark.primary)
            .tint(DesignSystem.Tokens.Theme.Text.StaticDark.primary)
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
        valueAccessibilityIdentifier: String,
        copyAccessibilityIdentifier: String,
        copyAction: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Tokens.Spacing.s050) {
            Text(label)
                .font(DesignSystem.Tokens.Font.Caption.medium)
                .foregroundStyle(DesignSystem.Tokens.Theme.Text.StaticDark.tertiary)

            HStack {
                Text(value)
                    .font(DesignSystem.Tokens.Font.Body.medium)
                    .foregroundStyle(DesignSystem.Tokens.Theme.Text.StaticDark.primary)
                    .accessibilityIdentifier(valueAccessibilityIdentifier)

                Spacer()

                Button(action: copyAction) {
                    Assets.copyNew.image
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: DesignSystem.Tokens.Size.s250, height: DesignSystem.Tokens.Size.s250)
                        .foregroundStyle(DesignSystem.Tokens.Theme.Text.StaticDark.tertiary)
                }
                .accessibilityIdentifier(copyAccessibilityIdentifier)
            }
        }
        .padding(DesignSystem.Tokens.Spacing.s150)
        .background(DesignSystem.Tokens.Theme.Text.StaticDark.primary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Tokens.CornerRadius._150, style: .continuous))
    }
}

private extension TangemPayCardDetailsViewRedesigned {
    enum Constants {
        static let plasticCardStandardWidthToHeightRatio = 1.586
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
