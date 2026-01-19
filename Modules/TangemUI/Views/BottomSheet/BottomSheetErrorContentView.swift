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
    private let icon: Icon
    private let title: String
    private let subtitle: String
    private let closeAction: (() -> Void)?
    private let primaryButton: MainButton.Settings?
    private let secondaryButton: MainButton.Settings?

    public init(
        icon: Icon = .attention,
        title: String,
        subtitle: String,
        closeAction: (() -> Void)? = nil,
        primaryButton: MainButton.Settings? = nil,
        secondaryButton: MainButton.Settings? = nil
    ) {
        self.icon = icon
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
                NavigationBarButton.close(action: closeAction)
                    .padding(.all, 16)
            }
        }
    }

    public var content: some View {
        VStack(spacing: .zero) {
            VStack(spacing: 24) {
                icon.icon.image
                    .resizable()
                    .frame(width: 32, height: 32)
                    .padding(12)
                    .background(Circle().fill(icon.overlay.opacity(0.1)))

                VStack(spacing: 8) {
                    Text(title)
                        .style(Fonts.Bold.title3, color: Colors.Text.primary1)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(subtitle)
                        .style(Fonts.Regular.subheadline, color: Colors.Text.secondary)
                        .fixedSize(horizontal: false, vertical: true)
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

public extension BottomSheetErrorContentView {
    struct Icon {
        public static let attention = Icon(icon: Assets.attention, overlay: Colors.Icon.attention)

        public let icon: ImageType
        public let overlay: Color

        public init(icon: ImageType, overlay: Color) {
            self.icon = icon
            self.overlay = overlay
        }
    }
}
