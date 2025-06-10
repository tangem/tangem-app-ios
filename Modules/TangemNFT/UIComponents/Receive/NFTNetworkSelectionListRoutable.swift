//
//  NFTNetworkSelectionListRoutable.swift
//  TangemNFT
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public protocol NFTNetworkSelectionListRoutable: AnyObject {
    func openReceive(for nftChainItem: NFTChainItem)
    func dismiss()
}
