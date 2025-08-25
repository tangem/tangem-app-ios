//
//  WalletConnectErrorViewState.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import struct SwiftUI.Color
import TangemAssets
import TangemLocalization

struct WalletConnectErrorViewState {
    let icon: Icon
    let title: String
    let subtitle: String
    let button: Button

    init(icon: Icon, title: String, subtitle: String, buttonStyle: Button.Style) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle

        button = .gotIt(style: buttonStyle)
    }
}

extension WalletConnectErrorViewState {
    struct Icon {
        let asset: ImageType
        let color: SwiftUI.Color

        static let walletConnect = Icon(asset: Assets.WalletConnect.walletConnectNew, color: Colors.Icon.informative)
        static let blockchain = Icon(asset: Assets.Glyphs.networkNew, color: Colors.Icon.informative)
        static let warning = Icon(asset: Assets.attention, color: Colors.Icon.attention)
    }

    struct Button {
        enum Style {
            case primary
            case secondary
        }

        let title: String
        let style: Style

        fileprivate static func gotIt(style: Style) -> Button {
            Button(title: Localization.balanceHiddenGotItButton, style: style)
        }
    }
}
