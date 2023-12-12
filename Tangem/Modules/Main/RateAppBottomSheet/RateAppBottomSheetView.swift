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
    }

    @ViewBuilder
    private var ratingSection: some View {
        HStack(spacing: 4.0) {
            ForEach(0 ..< 5) { _ in
                Image(systemName: Constants.sfSymbolsName)
                    .foregroundColor(Colors.Button.positive)
                    .font(.title3)
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
    }
}

// MARK: - Previews

#Preview {
    RateAppBottomSheetView(viewModel: RateAppBottomSheetViewModel(onInteraction: { print($0) }))
}
