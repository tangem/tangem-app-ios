//
//  WCConnectionNetworksView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct WCConnectionNetworksView: View {
    private var previewIconsCount: Int {
        min(4, tokenIconsInfo.count)
    }

    private let tokenIconsInfo: [TokenIconInfo]

    init(tokenIconsInfo: [TokenIconInfo]) {
        self.tokenIconsInfo = tokenIconsInfo
    }

    var body: some View {
        HStack(spacing: -4) {
            ForEach(0 ..< previewIconsCount, id: \.self) { index in
                iconItem(index: index)
                    .frame(size: .init(bothDimensions: 22))
            }
        }
    }

    @ViewBuilder
    private func iconItem(index: Int) -> some View {
        if index == 3, tokenIconsInfo.count > 4 {
            plusOneIcon
        } else {
            ZStack {
                Circle()
                    .foregroundStyle(Colors.Background.action)
                TokenIcon(tokenIconInfo: tokenIconsInfo[index], size: .init(bothDimensions: 20))
            }
        }
    }

    private var plusOneIcon: some View {
        ZStack {
            Circle()
                .foregroundStyle(Colors.Field.primary)
            Circle()
                .stroke(lineWidth: 2)
                .foregroundStyle(Colors.Background.action)
            Text("+\(tokenIconsInfo.count - 3)")
                .style(Fonts.Bold.caption2, color: Colors.Text.secondary)
        }
    }
}

#if DEBUG

#Preview {
    WCConnectionNetworksView(
        tokenIconsInfo: [
            TokenIconInfoBuilder().build(from: .blockchain(.init(.cosmos(testnet: true), derivationPath: nil)), isCustom: false),
            TokenIconInfoBuilder().build(from: .blockchain(.init(.ethereum(testnet: true), derivationPath: nil)), isCustom: false),
            TokenIconInfoBuilder().build(from: .blockchain(.init(.solana(curve: .ed25519_slip0010, testnet: true), derivationPath: nil)), isCustom: false),
            TokenIconInfoBuilder().build(from: .blockchain(.init(.bitcoin(testnet: true), derivationPath: nil)), isCustom: false),
        ]
    )
}

#endif
