//
//  TokenIcon.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

// [REDACTED_TODO_COMMENT]
struct TokenIconInfo: Hashable {
    let name: String
    let blockchainIconName: String?
    let imageURL: URL?
    let isCustom: Bool
    let customTokenColor: Color?
    let networkBorderColor: Color

    init(
        name: String,
        blockchainIconName: String?,
        imageURL: URL?,
        isCustom: Bool,
        customTokenColor: Color?,
        networkBorderColor: Color = Colors.Background.primary
    ) {
        self.name = name
        self.blockchainIconName = blockchainIconName
        self.imageURL = imageURL
        self.isCustom = isCustom
        self.customTokenColor = customTokenColor
        self.networkBorderColor = networkBorderColor
    }
}
