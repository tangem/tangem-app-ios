//
//  WCAssetIconHelper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

/// Helper for determining asset icon shape in WalletConnect transactions
enum WCAssetIconHelper {
    /// Determines cornerRadius for icon based on asset type
    /// - Parameter asset: Asset from Blockaid
    /// - Returns: cornerRadius value (round for tokens, square for NFTs)
    static func cornerRadius(for asset: BlockaidChainScanResult.Asset) -> CGFloat {
        if asset.isNFT {
            return 4.0 // Square shape for NFTs
        } else {
            return 20.0 // Round shape for tokens (half of icon size)
        }
    }

    /// Determines cornerRadius for icon based on size
    /// - Parameters:
    ///   - asset: Asset from Blockaid
    ///   - iconSize: Icon size
    /// - Returns: cornerRadius value
    static func cornerRadius(for asset: BlockaidChainScanResult.Asset, iconSize: CGSize) -> CGFloat {
        if asset.isNFT {
            return 4.0 // Square shape for NFTs
        } else {
            return iconSize.width / 2.0 // Round shape for tokens
        }
    }
}
