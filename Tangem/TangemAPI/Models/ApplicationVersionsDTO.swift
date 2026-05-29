//
//  ApplicationVersionsDTO.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct ApplicationVersionsDTO: Decodable {
    let forceUpdate: Bool
    let latestVersion: String?
    let minSupportedVersion: String?
}
