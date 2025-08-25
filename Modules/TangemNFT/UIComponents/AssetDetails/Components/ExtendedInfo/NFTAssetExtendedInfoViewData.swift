//
//  NFTAssetExtendedInfoViewData.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

public struct NFTAssetExtendedInfoViewData: Identifiable {
    public var id: String {
        title + " " + text
    }

    let title: String
    let text: String
}
