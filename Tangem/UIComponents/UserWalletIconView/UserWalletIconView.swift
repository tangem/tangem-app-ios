//
//  UserWalletIconView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct UserWalletIconView: View {
    let icon: UserWalletIcon
    let size: CGFloat

    var body: some View {
        switch icon {
        case .loadable(let imageProvider):
            LoadableWalletIconView(imageProvider: imageProvider, size: size)

        case .content(let content):
            WalletIconView(content: content, width: size)
        }
    }
}

// MARK: - LoadableWalletIconView

private struct LoadableWalletIconView: View {
    let imageProvider: any WalletImageProviding
    let size: CGFloat

    @State private var image: UIImage?

    var body: some View {
        WalletIconView(content: image.map(WalletIconContent.image), width: size)
            .task {
                guard image == nil else {
                    return
                }

                image = await imageProvider.loadSmallUIImage()
            }
    }
}
