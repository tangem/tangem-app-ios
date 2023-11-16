//
//  TokenIcon.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct TokenIconInfo: Hashable {
    let name: String
    let blockchainIconName: String?
    let imageURL: URL?
    let isCustom: Bool
    let customTokenColor: Color?

    init(
        name: String = "",
        blockchainIconName: String? = nil,
        imageURL: URL? = nil,
        isCustom: Bool = false,
        customTokenColor: Color? = nil
    ) {
        self.name = name
        self.blockchainIconName = blockchainIconName
        self.imageURL = imageURL
        self.isCustom = isCustom
        self.customTokenColor = customTokenColor
    }

    init(tokenItem: TokenItem) {
        name = tokenItem.name
        imageURL = tokenItem.id.map { TokenIconURLBuilder().iconURL(id: $0, size: .large) }
        customTokenColor = tokenItem.token?.customTokenColor
        blockchainIconName = tokenItem.blockchain.iconName
        isCustom = tokenItem.id == nil
    }
}
