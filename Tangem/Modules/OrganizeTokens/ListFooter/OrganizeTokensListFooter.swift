//
//  OrganizeTokensListFooter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct OrganizeTokensListFooter: View {
    let viewModel: OrganizeTokensViewModel
    let isTokenListFooterGradientHidden: Bool
    let cornerRadius: CGFloat
    let horizontalInset: CGFloat

    var body: some View {
        HStack(spacing: 8.0) {
            MainButton(
                title: Localization.commonCancel,
                style: .secondary,
                action: viewModel.onCancelButtonTap
            )

            MainButton(
                title: Localization.commonApply,
                style: .primary,
                action: viewModel.onApplyButtonTap
            )
        }
        .padding(.horizontal, horizontalInset)
        .background(
            OrganizeTokensListFooterOverlayView()
                .hidden(isTokenListFooterGradientHidden)
                .padding(.top, -45.0)
        )
    }
}
