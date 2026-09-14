//
//  NFTAccessibilityIdentifiers.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public enum NFTAccessibilityIdentifiers {
    private static let prefix = "nft"

    public static let mainEntrypointRow = "\(prefix)MainEntrypointRow"
    public static let collectionsReceiveButton = "\(prefix)CollectionsReceiveButton"
    public static let assetDetailsSendButton = "\(prefix)AssetDetailsSendButton"

    public static func collectionRow(name: String) -> String {
        "\(prefix)CollectionRow_\(name)"
    }

    public static func assetCell(name: String) -> String {
        "\(prefix)AssetCell_\(name)"
    }
}
