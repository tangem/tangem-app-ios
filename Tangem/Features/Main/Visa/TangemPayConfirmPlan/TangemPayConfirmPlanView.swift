//
//  TangemPayConfirmPlanView.swift
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

struct TangemPayConfirmPlanView: View {
    @ObservedObject var viewModel: TangemPayConfirmPlanViewModel

    var body: some View {
        content
            .background { background }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                footer
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbar }
            .alert(item: $viewModel.alert) { $0.alert }
            .modifyView { view in
                if #unavailable(iOS 26.0) {
                    view.backportTranslucentNavigationBar()
                } else {
                    view
                }
            }
    }

    private var content: some View {
        VStack(spacing: 0) {
            card
                .padding(.top, 8)

            Spacer(minLength: 24)

            VStack(alignment: .leading, spacing: 16) {
                Text(viewModel.title)
                    .style(DesignSystem.Font.headingMediumToken, color: DesignSystem.Color.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                pointsList
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }

    private var card: some View {
        KFImage(viewModel.cardImageURL.flatMap { URL(string: $0) })
            .placeholder {
                Assets.Visa.cardPlatinum.image
                    .resizable()
            }
            .resizable()
            .scaledToFit()
            .frame(width: Constants.cardWidth, height: Constants.cardHeight)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, Constants.cardLeadingInset)
    }

    private var pointsList: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(viewModel.points) { point in
                HStack(alignment: .top, spacing: 8) {
                    Assets.infoCircle20.image
                        .renderingMode(.template)
                        .foregroundStyle(DesignSystem.Color.iconPrimary)

                    Text(point.text)
                        .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text(Localization.tangempaySelectPlanConfirmTitle)
                .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
        }

        NavigationToolbarButton.close(placement: .topBarTrailing, action: viewModel.close)
    }

    private var footer: some View {
        VStack(spacing: 8) {
            TangemButtonV2(
                label: AttributedString(Localization.commonCancel),
                accessibilityLabel: Localization.commonCancel,
                action: viewModel.cancel
            )
            .size(.x12)
            .styleType(.secondary)
            .horizontalLayout(.infinity)
            .disabled(viewModel.isProcessing)

            TangemButtonV2(
                label: AttributedString(viewModel.confirmButtonTitle),
                accessibilityLabel: viewModel.confirmButtonTitle,
                action: viewModel.confirm
            )
            .size(.x12)
            .styleType(.default)
            .horizontalLayout(.infinity)
            .isLoading(viewModel.isProcessing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(alignment: .bottom) {
            BottomFadeWithBlur(backgroundColor: DesignSystem.Color.bgPrimary)
        }
    }

    private var background: some View {
        DesignSystem.Color.bgPrimary
            .overlay(alignment: .top) {
                LinearGradient(
                    colors: [Color.white.opacity(0.06), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 360)
            }
            .ignoresSafeArea()
    }
}

private extension TangemPayConfirmPlanView {
    enum Constants {
        static let cardWidth: CGFloat = 266
        static let cardHeight: CGFloat = 172
        static let cardLeadingInset: CGFloat = 24
    }
}
