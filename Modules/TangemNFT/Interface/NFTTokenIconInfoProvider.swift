//
//  NFTTokenIconInfoProvider.swift
//  TangemNFT
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemUI

public protocol NFTTokenIconInfoProvider {
    func tokenIconInfo(for nftChain: NFTChain, isCustom: Bool) -> TokenIconInfo
}
