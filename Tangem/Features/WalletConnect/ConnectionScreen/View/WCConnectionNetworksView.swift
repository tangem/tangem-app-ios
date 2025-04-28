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
                    .frame(size: .init(bothDimensions: 20))
            }
        }
    }
    
    @ViewBuilder
    private func iconItem(index: Int) -> some View {
        if index != 4, tokenIconsInfo.count < 4 {
            TokenIcon(tokenIconInfo: tokenIconsInfo[index], size: .init(bothDimensions: 20))
        } else {
            plusOneIcon
        }
    }
    
    private var plusOneIcon: some View {
        Text("+\(tokenIconsInfo.count - 3)")
            .style(Fonts.Regular.footnote, color: Colors.Text.primary1)
            .background(
                ZStack {
                    Circle()
                        .foregroundStyle(Colors.Field.primary)
                    Circle()
                        .stroke(lineWidth: 2)
                        .foregroundStyle(Colors.Background.action)
                }
            )
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
