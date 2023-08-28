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

    @State private var hasBottomSafeAreaInset = false

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
            .padding(.bottom, hasBottomSafeAreaInset ? 0.0 : 10.0) // Padding is added only on notchless devices
        }
        .padding(.horizontal, horizontalInset)
        .readGeometry(\.safeAreaInsets.bottom) { [oldValue = hasBottomSafeAreaInset] bottomInset in
            let newValue = bottomInset != 0.0
            if newValue != oldValue {
                hasBottomSafeAreaInset = newValue
            }
        }
        .background(
            OrganizeTokensListFooterOverlayView()
                .hidden(isTokenListFooterGradientHidden)
                .padding(.top, -45.0)
        )
    }
}
