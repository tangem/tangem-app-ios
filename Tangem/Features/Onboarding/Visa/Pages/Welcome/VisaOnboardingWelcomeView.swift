//
//  VisaOnboardingWelcomeView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemAssets

struct VisaOnboardingWelcomeView: View {
    @ObservedObject var viewModel: VisaOnboardingWelcomeViewModel

    private let imageWidthRatio: CGFloat = 0.707
    private let imageAspectRatio: CGFloat = 0.653
    private let backgroundCircleHorizontalOffset: CGFloat = 10
    private let verticalPaddingRatio: CGFloat = 0.119

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                let verticalPadding = verticalPaddingRatio * proxy.size.height
                ZStack {
                    let imageWidth = proxy.size.width * imageWidthRatio
                    let imageHeight = imageWidth * imageAspectRatio
                    let imageFrameSize = CGSize(width: imageWidth, height: imageHeight)
                    Circle()
                        .fill(Colors.Stroke.primary)
                        .frame(size: .init(bothDimensions: imageWidth - backgroundCircleHorizontalOffset * 2))

                    OnboardingCardView(
                        placeholderCardType: .dark,
                        cardImage: viewModel.cardImage,
                        cardScanned: true
                    )
                    .frame(size: imageFrameSize)
                }
                .padding(.top, verticalPadding)

                VStack(spacing: 14) {
                    Text(viewModel.title)
                        .style(Fonts.Bold.title1, color: Colors.Text.primary1)

                    Text(viewModel.description)
                        .multilineTextAlignment(.center)
                        .style(Fonts.Regular.callout, color: Colors.Text.secondary)
                }
                .padding(.top, verticalPadding)
                .padding(.horizontal, 26)

                Spacer()

                MainButton(
                    title: viewModel.activationButtonTitle,
                    icon: viewModel.isAccessCodeSet ? .trailing(Assets.tangemIcon) : nil,
                    isLoading: viewModel.isLoading,
                    action: viewModel.mainButtonAction
                )
                .padding(.bottom, 10)
                .padding(.horizontal, 16)
            }
        }
    }
}

#Preview {
    VisaOnboardingWelcomeView(viewModel: .init(
        activationState: .newActivation,
        isAccessCodeSet: false,
        imagePublisher: Just(nil),
        delegate: nil
    ))
}
