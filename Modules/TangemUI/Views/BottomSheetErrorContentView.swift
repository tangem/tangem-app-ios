//
//  BottomSheetErrorContentView.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUIUtils

public struct BottomSheetErrorContentView: View {
    private let title: String
    private let subtitle: String
    private let closeAction: (() -> Void)?
    private let primaryButton: MainButton.Settings?
    private let secondaryButton: MainButton.Settings?

    public init(
        title: String,
        subtitle: String,
        closeAction: (() -> Void)? = nil,
        primaryButton: MainButton.Settings? = nil,
        secondaryButton: MainButton.Settings? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.closeAction = closeAction
        self.primaryButton = primaryButton
        self.secondaryButton = secondaryButton
    }

    public var body: some View {
        ZStack(alignment: .topTrailing) {
            content

            if let closeAction {
                CircleButton.close(action: closeAction)
                    .padding(.all, 16)
            }
        }
    }

    public var content: some View {
        VStack(spacing: .zero) {
            VStack(spacing: 24) {
                Assets.attention.image
                    .resizable()
                    .frame(width: 32, height: 32)
                    .padding(12)
                    .background(Circle().fill(Colors.Icon.attention.opacity(0.1)))

                VStack(spacing: 8) {
                    Text(title)
                        .style(Fonts.Bold.title3, color: Colors.Text.primary1)

                    Text(subtitle)
                        .style(Fonts.Regular.subheadline, color: Colors.Text.secondary)
                }
                .multilineTextAlignment(.center)
            }
            .padding(.vertical, 50)
            .padding(.horizontal, 16)

            VStack(spacing: 8) {
                if let primaryButton {
                    MainButton(settings: primaryButton)
                }

                if let secondaryButton {
                    MainButton(settings: secondaryButton)
                }
            }
            .padding(.all, 16)
        }
        .infinityFrame(axis: .horizontal)
    }
}
