//
//  BasicTooltipView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

struct BasicTooltipView: View {
    // MARK: - Properties

    @Binding private(set) var isShowBindingValue: Bool
    private(set) var onHideAction: (() -> Void)?
    private(set) var title: String
    private(set) var message: String
    private(set) var leadingIcon: ImageType?

    // MARK: - UI

    var body: some View {
        ZStack {
            if isShowBindingValue {
                tooltipView
            }
        }
        .transition(.asymmetric(insertion: .move(edge: .top), removal: .opacity))
    }

    // MARK: - Private Implementation

    private var tooltipView: some View {
        VStack(spacing: .zero) {
            Spacer()

            HStack(alignment: .top, spacing: 12) {
                leadingIconView

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .lineLimit(1)
                        .style(Fonts.Bold.footnote, color: Colors.Text.primary1)

                    Text(message)
                        .lineLimit(2)
                        .style(Fonts.Regular.footnote, color: Colors.Text.secondary)
                }

                Spacer(minLength: 8)

                closeButton
            }
            .padding(.top, 12)
            .padding(.horizontal, 14)
            .padding(.bottom, 14)
            .defaultRoundedBackground(
                with: Colors.Background.primary,
                verticalPadding: .zero,
                horizontalPadding: .zero
            )
            .shadow(color: .black.opacity(0.12), radius: 40, x: 0, y: 4)

            Triangle()
                .foregroundStyle(Colors.Background.primary)
                .frame(size: .init(width: 20, height: 8))
                .rotationEffect(.degrees(180))
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 76)
    }

    @ViewBuilder
    private var leadingIconView: some View {
        if let leadingIcon {
            Circle()
                .fill(Colors.Icon.accent)
                .frame(size: .init(width: 20, height: 20))
                .overlay(
                    leadingIcon
                        .image
                        .renderingMode(.template)
                        .foregroundStyle(.white)
                        .frame(size: .init(width: 18, height: 18))
                )
        }
    }

    private var closeButton: some View {
        Button(action: {
            onHideAction?()
        }) {
            Assets.cross16
                .image
                .renderingMode(.template)
                .foregroundStyle(Colors.Text.secondary)
                .frame(width: 24, height: 24)
        }
        .buttonStyle(.plain)
    }
}
