//
//  ForYouAddFundsTokenSelectorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemAccounts
import TangemLocalization
import TangemUI
import TangemUIUtils

struct ForYouAddFundsTokenSelectorView: View {
    @ObservedObject var viewModel: ForYouAddFundsTokenSelectorViewModel

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 8) {
                    ForEach(viewModel.sections, content: sectionView)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, Constants.fadeHeight)
            }
            .overlay(fade, alignment: .bottom)

            cancelButton
        }
    }
}

private extension ForYouAddFundsTokenSelectorView {
    // MARK: - View properties

    var header: some View {
        ZStack {
            VStack(spacing: 0) {
                Text(viewModel.title)
                    .style(Font.Tangem.Heading17.semibold, color: DesignSystem.Color.textPrimary)

                Text(viewModel.subtitle)
                    .style(Font.Tangem.Body15.regular, color: DesignSystem.Color.textSecondary)
            }
            .frame(maxWidth: .infinity)

            HStack(spacing: 0) {
                Spacer()
                NavigationBarButton.close(action: viewModel.close)
            }
            .padding(.trailing, 12)
        }
        .padding(.vertical, 16)
    }

    func sectionView(_ section: ForYouAddFundsTokenSelectorViewModel.Section) -> some View {
        VStack(spacing: 0) {
            AccountInlineHeaderView(iconData: section.accountIcon, name: section.accountName)
                .nameStyle(Font.Tangem.Caption12.medium, color: DesignSystem.Color.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding([.horizontal, .top], 16)
                .padding(.bottom, 8)

            ForEach(section.rows, content: RowView.init)
        }
        .background(DesignSystem.Color.bgSecondary)
        .cornerRadius(24, corners: .allCorners)
    }

    var fade: some View {
        // Hand-rolled instead of DS `Fade`: its `.soft` variant fades only to 60% opacity — too transparent here.
        LinearGradient(
            colors: [DesignSystem.Color.bgPrimary.opacity(0), DesignSystem.Color.bgPrimary],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: Constants.fadeHeight)
        .allowsHitTesting(false)
    }

    var cancelButton: some View {
        TangemUI.Button(
            label: Localization.commonCancel,
            accessibilityLabel: nil,
            action: viewModel.close
        )
        .size(.x12)
        .styleType(.secondary)
        .horizontalLayout(.infinity)
        .padding(16)
    }

    enum Constants {
        static let fadeHeight: CGFloat = 40
    }
}
