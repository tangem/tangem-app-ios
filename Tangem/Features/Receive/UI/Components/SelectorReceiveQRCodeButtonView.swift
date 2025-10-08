//
//  SelectorReceiveQRCodeButtonView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization

struct SelectorReceiveQRCodeButtonView: View {
    let qrCodeAction: () -> Void

    var body: some View {
        VStack(alignment: .center, spacing: .zero) {
            Button {
                qrCodeAction()
            } label: {
                HStack(alignment: .center) {
                    Assets.qrCode
                        .image
                        .renderingMode(.template)
                        .resizable()
                        .frame(size: .init(bothDimensions: Layout.QRButtonView.iconSize))
                        .foregroundStyle(Colors.Icon.secondary)

                    Text(Localization.tokenReceiveShowQrCodeTitle)
                        .style(Fonts.Bold.subheadline, color: Colors.Text.secondary)
                }
            }
        }
        .padding(.vertical, Layout.QRButtonView.verticalPadding)
        .padding(.horizontal, Layout.QRButtonView.horizontalPadding)
    }
}

// MARK: - Layout

private extension SelectorReceiveQRCodeButtonView {
    enum Layout {
        enum QRButtonView {
            /// 20
            static let iconSize: CGFloat = 20

            /// 4
            static let verticalPadding: CGFloat = 4

            /// 6
            static let horizontalPadding: CGFloat = 6
        }
    }
}
