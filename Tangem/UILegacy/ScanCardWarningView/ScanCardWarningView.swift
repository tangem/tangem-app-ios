//
//  ScanCardWarningView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets

struct ScanCardWarningView: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 0) {
                HStack(spacing: 12) {
                    icon

                    VStack(alignment: .leading, spacing: 4) {
                        Text(Localization.mainScanCardWarningViewTitle)
                            .style(Fonts.Bold.subheadline, color: DesignSystem.Color.textPrimary)

                        Text(Localization.mainScanCardWarningViewSubtitle)
                            .style(Fonts.Regular.footnote, color: DesignSystem.Color.textSecondary)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Assets.chevron.image
            }
            .frame(maxWidth: .infinity)
            .padding([.vertical, .horizontal], 16)
            .background(DesignSystem.Color.bgSecondary)
            .cornerRadius(14)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var icon: some View {
        ZStack(alignment: .topTrailing) {
            Circle()
                .fill(DesignSystem.Color.bgPrimary)
                .frame(size: CGSize(bothDimensions: 42))
                .overlay(
                    Assets.tangemIcon.image
                        .renderingMode(.template)
                        .foregroundColor(.black)
                )

            Circle()
                .fill(DesignSystem.Color.iconAccentYellow)
                .padding(3)
                .background(DesignSystem.Color.bgSecondary)
                .frame(width: 12, height: 12)
                .cornerRadius(6)
        }
    }
}

#Preview {
    ZStack {
        DesignSystem.Color.bgPrimary

        ScanCardWarningView {}.padding()
    }
}
