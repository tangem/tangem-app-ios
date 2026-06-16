//
//  StakingTargetIconView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct StakingTargetIconView: View {
    let data: StakingTargetIconViewData
    let size: CGSize

    var body: some View {
        switch data {
        case .url(let url):
            IconView(url: url, size: size)
        case .asset(let asset):
            asset.image
                .resizable()
                .frame(width: size.width, height: size.height)
                .clipShape(Circle())
        }
    }
}
