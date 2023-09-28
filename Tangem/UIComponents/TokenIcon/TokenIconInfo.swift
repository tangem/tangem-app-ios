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
}
