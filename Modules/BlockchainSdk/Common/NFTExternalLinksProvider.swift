//
//  NFTExternalLinksProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public protocol NFTExternalLinksProvider {
    func url(tokenAddress: String, tokenID: String, contractType: String) -> URL?
}
