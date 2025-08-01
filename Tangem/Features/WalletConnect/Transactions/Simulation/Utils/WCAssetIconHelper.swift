//
//  WCAssetIconHelper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

enum WCAssetIconHelper {
    static func cornerRadius(for asset: BlockaidChainScanResult.Asset) -> CGFloat {
        if asset.isNFT {
            return 4.0
        } else {
            return 20.0
        }
    }

    static func cornerRadius(for asset: BlockaidChainScanResult.Asset, iconSize: CGSize) -> CGFloat {
        if asset.isNFT {
            return 4.0
        } else {
            return iconSize.width / 2.0
        }
    }
}
