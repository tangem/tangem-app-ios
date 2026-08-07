//
//  ApplicationVersionsDTO.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct ApplicationVersionsDTO: Codable, Equatable {
    let criticalVersion: String?
    let criticalOSVersion: String?
    let minSupportedVersion: String?
    let minSupportedOSVersion: String?
    let latestVersion: String?
}
