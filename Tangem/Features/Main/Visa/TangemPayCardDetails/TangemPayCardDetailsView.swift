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

struct TangemPayCardDetailsView: View {
    @ObservedObject var viewModel: TangemPayCardDetailsViewModel

    var body: some View {
        GeometryReader { geometry in
            Group {
                switch viewModel.state {
                case .loaded(let tangemPayCardDetailsData):
                    loadedStateContent(cardDetails: tangemPayCardDetailsData)
                case .hidden(let isFrozen):
                    hiddenStateContent(isFrozen: isFrozen, isLoading: false)
                case .loading(let isFrozen):
                    hiddenStateContent(isFrozen: isFrozen, isLoading: true)
                }
            }
            .frame(
                width: geometry.size.width,
                height: geometry.size.width / Constants.plasticCardStandardWidthToHeightRatio
            )
            .background(Color.black)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .aspectRatio(Constants.plasticCardStandardWidthToHeightRatio, contentMode: .fit)
    }

    private func hiddenStateContent(isFrozen: Bool, isLoading: Bool) -> some View {
        VStack {
            HStack {
                Spacer()

                if viewModel.state.showDetailsButtonVisible {
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
                            )
                    }
                }
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

                Assets.Visa.logo.image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 24)
            }
        }
        .padding(16)
        .background(
            Assets.Visa.cardOverlay.image
                .resizable()
                .aspectRatio(contentMode: .fill)
        )
        .overlay {
            if isFrozen {
                Assets.Visa.cardOverlayFrozen.image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }
        }
    }

    private func loadedStateContent(cardDetails: TangemPayCardDetailsData) -> some View {
        VStack {
            HStack {
                Spacer()

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
            }

            Spacer()

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
        }
        .padding(16)
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
