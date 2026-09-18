//
//  PolymarketRegionRestrictionView.swift
//  TangemPolymarketUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

public struct PolymarketRegionRestrictionView: View {
    @ObservedObject private var viewModel: PolymarketRegionRestrictionViewModel

    public init(viewModel: PolymarketRegionRestrictionViewModel) {
        _viewModel = ObservedObject(wrappedValue: viewModel)
    }

    public var body: some View {
        VStack(spacing: 0) {
            closeButton

            VStack(spacing: Constants.contentSpacing) {
                icon

                texts
            }
            .padding(.horizontal, Constants.horizontalPadding)
            .padding(.top, Constants.contentTopPadding)
            .padding(.bottom, Constants.contentSpacing)

            TangemUI.Button(
                label: Localization.commonClose,
                accessibilityLabel: nil,
                action: viewModel.onCloseTap
            )
            .styleType(.default)
            .size(.x12)
            .horizontalLayout(.infinity)
            .padding(.horizontal, Constants.buttonHorizontalPadding)
            .padding(.vertical, Constants.buttonVerticalPadding)
        }
        .floatingSheetConfiguration { configuration in
            configuration.backgroundInteractionBehavior = .tapToDismiss
            configuration.sheetBackgroundColor = DesignSystem.Color.bgSecondary
        }
    }

    private var closeButton: some View {
        HStack(spacing: 0) {
            Spacer(minLength: 0)

            TangemUI.Button(
                icon: DesignSystem.Icons.Cross.regular20,
                accessibilityLabel: Localization.commonClose,
                action: viewModel.onCloseTap
            )
            .size(.x11)
            .styleType(.material(.glass))
        }
        .padding(Constants.horizontalPadding)
    }

    private var icon: some View {
        DesignSystem.Icons.Error.regular28.image
            .renderingMode(.template)
            .resizable()
            .frame(width: Constants.iconSize, height: Constants.iconSize)
            .foregroundStyle(DesignSystem.Color.iconStatusWarning)
            .frame(width: Constants.avatarSize, height: Constants.avatarSize)
            .background(DesignSystem.Color.bgStatusWarningSubtle, in: Circle())
    }

    private var texts: some View {
        VStack(spacing: Constants.textsSpacing) {
            Text(viewModel.title)
                .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textPrimary)

            Text(viewModel.message)
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Constants

private extension PolymarketRegionRestrictionView {
    enum Constants {
        static let horizontalPadding: CGFloat = 16
        static let contentTopPadding: CGFloat = 16
        static let contentSpacing: CGFloat = 32
        static let textsSpacing: CGFloat = 8
        static let iconSize: CGFloat = 28
        static let avatarSize: CGFloat = 80
        static let buttonHorizontalPadding: CGFloat = 16
        static let buttonVerticalPadding: CGFloat = 12
    }
}

// MARK: - Previews

#Preview {
    PolymarketRegionRestrictionView(viewModel: .regionRestriction(onClose: {}))
}
