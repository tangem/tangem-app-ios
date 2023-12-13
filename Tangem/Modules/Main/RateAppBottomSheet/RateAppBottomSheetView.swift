//
//  RateAppBottomSheetView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct RateAppBottomSheetView: View {
    @ObservedObject var viewModel: RateAppBottomSheetViewModel

    /// - Note: `Bool` can't be used as an element of this array because it doesn't conform to `VectorArithmetic`.
    /// Therefore `CGFloat` in the range `0...1` is used instead.
    @State private var ratingAnimations: [CGFloat] = Array(repeating: .zero, count: Constants.ratingSymbolsCount)

    var body: some View {
        VStack(spacing: 0.0) {
            FixedSpacer.vertical(82.0 - Constants.bottomSheetTopNotchHeight)

            ratingSection

            FixedSpacer.vertical(45.0)

            textSection

            FixedSpacer.vertical(55.0)

            buttonsSection

            FixedSpacer.vertical(footerHeight)
        }
        .padding(.horizontal, Constants.horizontalPadding)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + Constants.ratingAnimationDelay) {
                for (index, delay) in stride(
                    from: .zero,
                    to: Constants.ratingAnimationTotalDuration,
                    by: Constants.ratingAnimationDuration
                ).enumerated() {
                    withAnimation(.linear(duration: Constants.ratingAnimationDuration).delay(delay)) {
                        ratingAnimations[index] = 1.0
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var ratingSection: some View {
        HStack(spacing: 4.0) {
            ForEach(0 ..< Constants.ratingSymbolsCount, id: \.self) { index in
                Image(systemName: Constants.sfSymbolsName)
                    .foregroundColor(Colors.Button.positive)
                    .font(.title3)
                    .scaleEffect(.init(bothDimensions: ratingAnimations[index] == 1.0 ? 0.75 : 1.0))
                    .onAnimationCompleted(for: ratingAnimations[index]) {
                        withAnimation(.linear(duration: Constants.ratingAnimationDuration)) {
                            ratingAnimations[index] = .zero
                        }
                    }
            }
        }
    }

    @ViewBuilder
    private var textSection: some View {
        VStack(spacing: Constants.interItemSpacing) {
            Group {
                Text(Localization.rateAppSheetTitle)
                    .style(.title.bold(), color: Colors.Text.primary1)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

                Text(Localization.rateAppSheetSubtitle)
                    .style(.subheadline, color: Colors.Text.secondary)
                    .lineLimit(nil)
                    .layoutPriority(1000.0)
            }
            .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 34.0 - Constants.horizontalPadding)
    }

    @ViewBuilder
    private var buttonsSection: some View {
        VStack(spacing: Constants.interItemSpacing) {
            MainButton(
                title: Localization.rateAppSheetPositiveResponseButtonTitle,
                style: .primary,
                action: viewModel.onRateAppSheetPositiveResponse
            )

            MainButton(
                title: Localization.rateAppSheetNegativeResponseButtonTitle,
                style: .secondary,
                action: viewModel.onRateAppSheetNegativeResponse
            )
        }
    }

    private var footerHeight: CGFloat {
        // Different padding on devices with/without notch
        return UIApplication.safeAreaInsets.bottom.isZero ? 12.0 : 6.0
    }
}

// MARK: - Constants

private extension RateAppBottomSheetView {
    private enum Constants {
        static let bottomSheetTopNotchHeight = 22.0
        static let horizontalPadding = 16.0
        static let interItemSpacing = 10.0
        static let sfSymbolsName = "star.fill"
        static let ratingSymbolsCount = 5
        static let ratingAnimationDuration = 0.09
        static var ratingAnimationTotalDuration: TimeInterval { ratingAnimationDuration * TimeInterval(ratingSymbolsCount) }
        static let ratingAnimationDelay = 0.7
    }
}

// MARK: - Previews

#Preview {
    RateAppBottomSheetView(viewModel: RateAppBottomSheetViewModel(onInteraction: { print($0) }))
}
