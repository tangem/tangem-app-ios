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
    private let gotItButtonAction: () -> Void

    public init(title: String, subtitle: String, gotItButtonAction: @escaping () -> Void) {
        self.title = title
        self.subtitle = subtitle
        self.gotItButtonAction = gotItButtonAction
    }

    public var body: some View {
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
                .disableAnimations()
            }
            .padding(.vertical, 50)

            MainButton(title: Localization.commonGotIt, style: .secondary, action: gotItButtonAction)
        }
        .infinityFrame(axis: .horizontal)
    }
}
