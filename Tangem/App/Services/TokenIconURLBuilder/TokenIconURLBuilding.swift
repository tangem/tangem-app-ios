//
//  TokenIconURLBuilding.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

protocol TokenIconURLBuilding {
    func iconURL(id: String, size: TokenURLIconSize) -> URL
}
