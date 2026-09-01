//
//  TangemPayCashbackTiersView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemUIUtils
import TangemAssets
import TangemLocalization

struct TangemPayCashbackTiersView: View {
    let data: TangemPayCashbackTiersViewData
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 16)

            rows
        }
    }
}

// MARK: - Subviews

private extension TangemPayCashbackTiersView {
    var header: some View {
        BottomSheetHeaderView(title: data.title, trailing: {
            TangemUI.Button(
                icon: DesignSystem.Icons.Cross.regular20,
                accessibilityLabel: Localization.commonClose,
                action: onClose
            )
            .size(.x11)
            .styleType(.material(.glass))
        })
        .titleFont(DesignSystem.Font.bodyMediumToken.font)
        .titleColor(DesignSystem.Color.textPrimary)
    }

    var rows: some View {
        VStack(spacing: 0) {
            ForEach(data.rows) { row in
                TangemUI.Row(title: row.text)
                    .titleLineLimit(nil)
                    .verticalAlignment(.top)
                    .showDivider(row.id != data.rows.last?.id)
                    .start {
                        DesignSystem.Icons.Info.regular20.image
                            .renderingMode(.template)
                            .foregroundStyle(DesignSystem.Color.iconSecondary)
                    }
            }
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Single tier") {
    TangemPayCashbackTiersView(data: .preview, onClose: {})
        .background(DesignSystem.Color.bgSecondary)
}

#Preview("Multiple tiers") {
    TangemPayCashbackTiersView(data: .previewMultipleTiers, onClose: {})
        .background(DesignSystem.Color.bgSecondary)
}
#endif
