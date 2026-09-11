//
//  JointAccountMemberDetailsView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

struct JointAccountMemberDetailsView: View {
    let viewModel: JointAccountMemberDetailsViewModel

    var body: some View {
        VStack(spacing: .zero) {
            FloatingSheetNavigationBarView(
                backgroundColor: DesignSystem.Color.bgSecondary,
                closeButtonAction: viewModel.onCloseTap
            )

            content
                .padding(.horizontal, Constants.horizontalPadding)
                .padding(.vertical, Constants.contentVerticalPadding)

            closeButton
                .padding(Constants.horizontalPadding)
        }
        .floatingSheetConfiguration {
            $0.sheetBackgroundColor = DesignSystem.Color.bgSecondary
            $0.backgroundInteractionBehavior = .tapToDismiss
        }
    }

    private var content: some View {
        VStack(spacing: Constants.avatarSpacing) {
            avatar

            VStack(spacing: Constants.identitySpacing) {
                Text(viewModel.name)
                    .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)
                    .multilineTextAlignment(.center)

                Text(viewModel.address)
                    .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textPrimary)
                    .multilineTextAlignment(.center)

                copyButton
                    .padding(.top, Constants.copyButtonTopPadding)
            }
            .padding(.horizontal, Constants.identityHorizontalPadding)
        }
    }

    private var avatar: some View {
        Circle()
            .fill(viewModel.accentColor)
            .frame(size: Constants.avatarSize)
            .overlay {
                Text(viewModel.monogram)
                    .style(
                        DesignSystem.Font.headingMediumToken,
                        color: DesignSystem.Color.textStaticDarkPrimary
                    )
            }
    }

    private var copyButton: some View {
        TangemUI.Button(
            label: Localization.addressBookCopyAddress,
            accessibilityLabel: Localization.addressBookCopyAddress,
            action: viewModel.onCopyTap
        )
        .iconEnd(DesignSystem.Icons.Copy.regular20)
        .styleType(.secondary)
        .size(.x9)
        .horizontalLayout(.intrinsic)
    }

    private var closeButton: some View {
        TangemUI.Button(
            label: Localization.commonClose,
            accessibilityLabel: Localization.commonClose,
            action: viewModel.onCloseTap
        )
        .styleType(.secondary)
        .size(.x12)
        .horizontalLayout(.infinity)
    }
}

// MARK: - Constants

private extension JointAccountMemberDetailsView {
    enum Constants {
        static let horizontalPadding: CGFloat = 16
        static let contentVerticalPadding: CGFloat = 16
        static let avatarSpacing: CGFloat = 32
        static let identitySpacing: CGFloat = 8
        static let identityHorizontalPadding: CGFloat = 32
        static let copyButtonTopPadding: CGFloat = 16
        static let avatarSize = CGSize(bothDimensions: 72)
    }
}

// MARK: - Previews

#Preview {
    JointAccountMemberDetailsView(
        viewModel: JointAccountMemberDetailsViewModel(
            name: "Isaac",
            address: "0xBef7B36845000000000000ac4e6752A9cE000000",
            accentColor: DesignSystem.Color.bgAccentBlue,
            coordinator: nil
        )
    )
    .frame(maxHeight: .infinity, alignment: .bottom)
    .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
}
