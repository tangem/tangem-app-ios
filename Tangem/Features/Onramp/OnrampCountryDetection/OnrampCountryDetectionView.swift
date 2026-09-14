//
//  OnrampCountryView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUI
import TangemUIUtils

struct OnrampCountryDetectionView: View {
    @ObservedObject private var viewModel: OnrampCountryDetectionViewModel

    init(viewModel: OnrampCountryDetectionViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: 24) {
            BottomSheetHeaderView(title: Localization.onrampResidencyBottomsheetTitle)

            contentView

            buttons
        }
        .padding([.horizontal, .top], 16)
        .background(Colors.Background.tertiary)
        .presentationDetents(idealHeight: Constants.idealContentHeight)
        .presentationDragIndicator(.visible)
        .onAppear(perform: viewModel.onAppear)
    }

    private var contentView: some View {
        VStack(spacing: 12) {
            IconView(url: viewModel.iconURL, size: CGSize(width: 36, height: 36), forceKingfisher: true)

            VStack(spacing: 6) {
                Text(viewModel.title)
                    .style(Fonts.Bold.callout, color: Colors.Text.primary1)

                switch viewModel.style {
                case .info:
                    EmptyView()
                case .notSupport:
                    Text(Localization.onrampResidencyBottomsheetCountryNotSupported)
                        .style(Fonts.Regular.footnote, color: Colors.Text.warning)
                }
            }
        }
    }

    private var buttons: some View {
        VStack(spacing: 10) {
            MainButton(
                title: Localization.commonChange,
                style: .secondary,
                action: viewModel.didTapChangeButton
            )

            MainButton(
                title: viewModel.mainButtonTitle,
                action: viewModel.didTapMainButton
            )
        }
    }
}

private extension OnrampCountryDetectionView {
    enum Constants {
        static let idealContentHeight: CGFloat = 278
    }
}
