//
//  EarnProductDetailsDemo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct EarnProductDetailsDemoView: View {
    @State private var isRightToLeft = false
    @State private var linkTapCount = 0
    @State private var presentedInfo: EarnProductDetails.InfoSheet?

    private let details = EarnProductDetails.preview

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                controls
                    .padding(.horizontal, 16)

                VStack(spacing: 0) {
                    EarnProductBenefitsView(benefits: details.benefits)

                    EarnProductDetailsView(
                        details: details,
                        onLinkTap: { _ in linkTapCount += 1 },
                        onInfoTap: { presentedInfo = $0 }
                    )
                }
                .environment(\.layoutDirection, isRightToLeft ? .rightToLeft : .leftToRight)
            }
            .padding(.vertical, 16)
        }
        .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
        .navigationTitle("Earn product details")
        .modal(
            item: $presentedInfo,
            contentLayout: .intrinsic,
            navigation: .title(presentedInfo?.title ?? "")
        ) { info in
            EarnProductInfoSheetView(sheet: info)
                .environment(\.layoutDirection, isRightToLeft ? .rightToLeft : .leftToRight)
        }
    }
}

// MARK: - Subviews

private extension EarnProductDetailsDemoView {
    var controls: some View {
        VStack(spacing: 8) {
            Toggle("Right to left", isOn: $isRightToLeft)

            HStack {
                Text("Link taps")
                Spacer()
                Text("\(linkTapCount)")
            }
        }
        .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
    }
}
