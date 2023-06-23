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
    let tokenListFooterFrameMinY: Binding<CGFloat>
    let scrollViewBottomContentInset: Binding<CGFloat>
    let contentHorizontalInset: CGFloat
    let isTokenListFooterGradientHidden: Bool
    let cornerRadius: CGFloat

    var body: some View {
        HStack(spacing: 8.0) {
            Group {
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
            .background(
                Colors.Background
                    .primary
                    .cornerRadiusContinuous(cornerRadius)
            )
        }
        .padding(.horizontal, contentHorizontalInset)
        .padding(.bottom, 8.0)
        .background(OrganizeTokensListFooterOverlayView().hidden(isTokenListFooterGradientHidden))
        .readGeometry { geometryInfo in
            tokenListFooterFrameMinY.wrappedValue = geometryInfo.frame.minY
            scrollViewBottomContentInset.wrappedValue = geometryInfo.size.height
        }
        .infinityFrame(alignment: .bottom)
    }
}
