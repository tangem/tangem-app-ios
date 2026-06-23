//
//  SendReceiveTokenSwapRequiredContentView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemFoundation
import TangemUI
import TangemAccessibilityIdentifiers

struct SendReceiveTokenSwapRequiredViewData: Equatable {
    let iconURL: URL
    let title: String
    let subtitle: String
    let buttonTitle: String

    @IgnoredEquatable
    var swapAction: () -> Void
}

/// "{Token} is not supported in Swap & Send" sheet content offering a redirect to the regular swap.
/// Layout mirrors `BottomSheetErrorContentView`; the icon is the coin's icon with a swap badge.
struct SendReceiveTokenSwapRequiredContentView: View {
    let viewData: SendReceiveTokenSwapRequiredViewData

    var body: some View {
        VStack(spacing: .zero) {
            VStack(spacing: 24) {
                icon

                VStack(spacing: 8) {
                    Text(viewData.title)
                        .style(Fonts.Bold.title3, color: Colors.Text.primary1)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier(SendAccessibilityIdentifiers.networkSelectorSwapRequiredTitle)

                    Text(viewData.subtitle)
                        .style(Fonts.Regular.subheadline, color: Colors.Text.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .multilineTextAlignment(.center)
            }
            .padding(.vertical, 50)
            .padding(.horizontal, 16)

            MainButton(
                settings: .init(
                    title: viewData.buttonTitle,
                    style: .secondary,
                    accessibilityIdentifier: SendAccessibilityIdentifiers.networkSelectorSwapTokenButton,
                    action: viewData.swapAction
                )
            )
            .padding(.all, 16)
        }
        .infinityFrame(axis: .horizontal)
    }

    private var icon: some View {
        IconView(url: viewData.iconURL, size: CGSize(width: 56, height: 56), forceKingfisher: true)
            .overlay(alignment: .bottomTrailing) {
                badge
                    .offset(x: 4, y: 4)
            }
    }

    private var badge: some View {
        Assets.exchangeMini.image
            .resizable()
            .renderingMode(.template)
            .frame(width: 14, height: 14)
            .foregroundColor(Colors.Icon.primary2)
            .padding(5)
            .background(Circle().fill(Colors.Icon.primary1))
            .padding(2)
            .background(Circle().fill(Colors.Background.primary))
    }
}
