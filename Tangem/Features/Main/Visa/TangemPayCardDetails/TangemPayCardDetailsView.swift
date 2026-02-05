//
//  TangemPayCardDetailsView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUIUtils

struct TangemPayCardDetailsView: View {
    @ObservedObject var viewModel: TangemPayCardDetailsViewModel

    @State private var animationProgress: CGFloat = .zero
    @State private var onHalfFlipCalled: Bool = false

    @ScaledMetric(relativeTo: .body) var cardNumberHeight: CGFloat = 16

    var body: some View {
        Group {
            switch viewModel.state {
            case .loaded(let state):

                switch state {
                case .revealed(let data):
                    loadedStateContent(
                        cardDetails: data,
                        isRevealed: true
                    )
                case .unrevealed(let data, let isLoading):
                    loadedStateContent(
                        cardDetails: data,
                        isRevealed: false,
                        isLoading: isLoading
                    )
                }
            case .hidden(let isFrozen):
                hiddenStateContent(isFrozen: isFrozen, isLoading: false)
            case .loading(let isFrozen):
                hiddenStateContent(isFrozen: isFrozen, isLoading: true)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .aspectRatio(Constants.plasticCardStandardWidthToHeightRatio, contentMode: .fit)
        .background(Color.Tangem.Visa.cardDetailBackground, in: RoundedRectangle(cornerRadius: 14))
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

    private func hiddenStateContent(isFrozen: Bool, isLoading: Bool) -> some View {
        VStack {
            HStack(alignment: .center, spacing: 6) {
                Spacer()

                Assets.Visa.logo.image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 24)
            }

            Spacer()

            HStack(alignment: .center, spacing: 6) {
                Text("*" + viewModel.lastFourDigits)
                    .style(
                        Fonts.Regular.body,
                        color: Colors.Text.constantWhite
                    )

                Group {
                    if isLoading {
                        CircularActivityIndicator(color: .white, lineWidth: 1.5)
                    } else if isFrozen {
                        Image(systemName: "snowflake")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .foregroundColor(.white)
                    }
                }
                .frame(width: 16, height: 16)

                Spacer()

                if viewModel.state.showDetailsButtonVisible {
                    showDetailsButton()
                }
            }
            .frame(height: cardNumberHeight)
        }
        .padding(16)
        .background(
            Assets.Visa.cardOverlay.image
                .resizable()
                .aspectRatio(contentMode: .fill)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    LinearGradient(stops: [
                        .init(color: Colors.Stroke.primary.opacity(0.1), location: 0),
                        .init(color: Colors.Stroke.primary, location: 1),
                    ], startPoint: .bottomLeading, endPoint: .topTrailing),
                    lineWidth: 2
                )
        }
        .overlay {
            if isFrozen {
                Assets.Visa.cardOverlayFrozen.image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }
        }
    }

    private func loadedStateContent(
        cardDetails: TangemPayCardDetailsData,
        isRevealed: Bool,
        isLoading: Bool = false
    ) -> some View {
        VStack {
            VStack(spacing: 12) {
                cardDetailField(
                    label: Localization.tangempayCardDetailsCardNumber,
                    value: cardDetails.number,
                    copyAction: viewModel.copyNumber
                )

                HStack(spacing: 12) {
                    cardDetailField(
                        label: Localization.tangempayCardDetailsExpiry,
                        value: cardDetails.expirationDate,
                        copyAction: viewModel.copyExpirationDate
                    )

                    cardDetailField(
                        label: Localization.tangempayCardDetailsCvc,
                        value: cardDetails.cvc,
                        copyAction: viewModel.copyCVC
                    )
                }
            }

            Spacer()

            HStack {
                if isLoading {
                    CircularActivityIndicator(color: .white, lineWidth: 1.5)
                        .frame(width: 16, height: 16)
                }

                Spacer()

                if isRevealed {
                    Button(action: viewModel.toggleVisibility) {
                        Text(Localization.tangempayCardDetailsHideDetails)
                            .style(
                                Fonts.Regular.footnote,
                                color: Colors.Text.constantWhite
                            )
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Colors.Text.tertiary.opacity(0.2))
                            )
                    }
                } else {
                    showDetailsButton()
                }
            }
        }
        .padding(16)
    }

    private func showDetailsButton() -> some View {
        Button(action: viewModel.toggleVisibility) {
            Text(Localization.tangempayCardDetailsShowDetails)
                .style(
                    Fonts.Regular.footnote,
                    color: Colors.Text.constantWhite
                )
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Colors.Text.tertiary.opacity(0.2))
                        .drawingGroup(opaque: true)
                )
        }
        .cornerRadius(14)
    }

    private func cardDetailField(label: String, value: String, copyAction: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .style(
                    Fonts.Regular.caption2,
                    color: Colors.Text.tertiary
                )

            HStack {
                Text(value)
                    .style(
                        Fonts.Regular.subheadline,
                        color: Colors.Text.constantWhite
                    )
                    .screenCaptureProtection()
                    .fixedSize()

                Spacer()

                Button(action: copyAction) {
                    Assets.copyNew.image
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(size: .init(bothDimensions: 20))
                        .foregroundColor(Colors.Text.tertiary)
                }
            }
        }
        .padding(12)
        .background(Colors.Text.tertiary.opacity(0.2))
        .cornerRadius(10)
    }
}

private extension TangemPayCardDetailsView {
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
