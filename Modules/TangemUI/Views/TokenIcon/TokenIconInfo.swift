//
//  TokenIcon.swift
//  TangemUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

// [REDACTED_TODO_COMMENT]
// TODO: What the heck does the [REDACTED_TODO_COMMENT]
public struct TokenIconInfo: Hashable {
    public let name: String
    public let blockchainIconAsset: ImageType?
    public let imageURL: URL?
    public let isCustom: Bool
    public let customTokenColor: Color?
    public let networkBorderColor: Color

    public init(
        name: String,
        blockchainIconAsset: ImageType?,
        imageURL: URL?,
        isCustom: Bool,
        customTokenColor: Color?,
        networkBorderColor: Color = Colors.Background.primary
    ) {
        self.name = name
        self.blockchainIconAsset = blockchainIconAsset
        self.imageURL = imageURL
        self.isCustom = isCustom
        self.customTokenColor = customTokenColor
        self.networkBorderColor = networkBorderColor
    }

    /// A token backed only by a remote logo — no network badge and not a custom token.
    /// Fits list/market surfaces that render a bare icon from a URL.
    public static func remote(name: String, imageURL: URL?) -> TokenIconInfo {
        TokenIconInfo(
            name: name,
            blockchainIconAsset: nil,
            imageURL: imageURL,
            isCustom: false,
            customTokenColor: nil
        )
    }
}
