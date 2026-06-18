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
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .aspectRatio(Constants.plasticCardStandardWidthToHeightRatio, contentMode: .fit)
        .background(
            Color.Tangem.Visa.cardDetailBackground,
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
        .padding(16)
        .background(cardArtBackground)
    }

    private func hiddenStateContent(isFrozen: Bool, isLoading: Bool) -> some View {
        VStack {
            cardHeader

            Spacer()

            HStack(alignment: .bottom, spacing: 6) {
                VStack(alignment: .leading, spacing: 2) {
                    cardNameContent()

                    HStack(spacing: 6) {
                        Text("*" + viewModel.lastFourDigits)
                            .font(DesignSystem.Font.bodyMediumToken)
                            .foregroundStyle(DesignSystem.Color.textStaticDarkPrimary)

                        Group {
                            if isLoading {
                                CircularActivityIndicator(color: .white, lineWidth: 1.5)
                            } else if isFrozen {
                                DesignSystem.Icons.Snowflake.regular16.image
                                    .renderingMode(.template)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .foregroundStyle(DesignSystem.Color.textStaticDarkPrimary)
                            }
                        }
                        .frame(width: 16, height: 16)
                    }
                }

                Spacer()
            }
        }
        .padding(16)
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
            VStack(spacing: 12) {
                cardDetailField(
                    label: Localization.tangempayCardDetailsCardNumber,
                    value: cardDetails.number,
                    valueAccessibilityIdentifier: TangemPayAccessibilityIdentifiers.cardDetailsNumberValue,
                    copyAccessibilityIdentifier: TangemPayAccessibilityIdentifiers.cardDetailsCopyNumber,
                    copyAction: viewModel.copyNumber
                )

                HStack(spacing: 12) {
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
                        .frame(width: 16, height: 16)
                }

                Spacer()

                closeButton
            }
        }
        .padding(16)
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
                .frame(width: 20, height: 20)
                .foregroundStyle(DesignSystem.Color.textStaticDarkPrimary)
                .padding(6)
                .background(DesignSystem.Color.bgOpaquePrimary, in: Circle())
        }
        .accessibilityIdentifier(TangemPayAccessibilityIdentifiers.cardDetailsHideButton)
        .accessibilityLabel(Text(Localization.tangempayCardDetailsHideDetails))
    }

    private var cardHeader: some View {
        HStack(alignment: .center, spacing: 6) {
            DesignSystem.Icons.Cloud.filled12.image
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 10)
                .foregroundStyle(DesignSystem.Color.textStaticDarkPrimary)

            Text(Localization.tangempayDigitalCard)
                .font(DesignSystem.Font.bodyMediumToken)
                .foregroundStyle(DesignSystem.Color.textStaticDarkPrimary)

            Spacer()
        }
        .padding(.top, 4)
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
                .font(DesignSystem.Font.bodyMediumToken)
                .foregroundStyle(DesignSystem.Color.textStaticDarkSecondary)
        case .interactive:
            Button(action: viewModel.cardNameTapped) {
                HStack(spacing: 4) {
                    Text(viewModel.cardName)
                        .font(DesignSystem.Font.bodyMediumToken)
                        .foregroundStyle(DesignSystem.Color.textStaticDarkSecondary)

                    DesignSystem.Icons.Edit.regular20.image
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 20, height: 20)
                        .foregroundStyle(DesignSystem.Color.textStaticDarkPrimary)
                }
            }
        case .editing:
            TextField(
                text: $viewModel.cardName,
                label: {
                    Text(Localization.tangempayCardDetailsRenameCardPlaceholder)
                        .font(DesignSystem.Font.bodyMediumToken)
                        .foregroundStyle(DesignSystem.Color.textStaticDarkTertiary)
                }
            )
            .font(DesignSystem.Font.bodyMediumToken)
            .foregroundStyle(DesignSystem.Color.textStaticDarkPrimary)
            .tint(DesignSystem.Color.textStaticDarkPrimary)
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
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(DesignSystem.Font.captionMediumToken)
                .foregroundStyle(DesignSystem.Color.textStaticDarkTertiary)

            HStack {
                Text(value)
                    .font(DesignSystem.Font.bodyMediumToken)
                    .foregroundStyle(DesignSystem.Color.textStaticDarkPrimary)
                    .accessibilityIdentifier(valueAccessibilityIdentifier)

                Spacer()

                Button(action: copyAction) {
                    DesignSystem.Icons.Copy.regular20.image
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                        .foregroundStyle(DesignSystem.Color.textStaticDarkTertiary)
                }
                .accessibilityIdentifier(copyAccessibilityIdentifier)
            }
        }
        .padding(12)
        .background(DesignSystem.Color.textStaticDarkPrimary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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
