//
//  MCPAgentIconView.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import Kingfisher
import TangemAssets
import TangemUI

struct MCPAgentIconView: View {
    let iconURL: URL?
    let imageCache: Kingfisher.ImageCache

    var body: some View {
        KFImage(iconURL)
            .placeholder {
                Shimmer()
            }
            .onFailureView {
                DesignSystem.Icons.Server.filled32.image
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .foregroundStyle(DesignSystem.Color.iconBrand)
                    .frame(width: 40, height: 40)
                    .background(DesignSystem.Color.bgStatusInfoSubtle)
            }
            .targetCache(imageCache)
            .resizable()
            .scaledToFit()
            .frame(width: 40, height: 40)
            .clipShape(.rect(cornerRadius: 12))
    }
}
