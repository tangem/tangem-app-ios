//
//  SeedNotifyDTO.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

enum SeedNotifyStatus: String, Codable {
    case notified
    case declined
    case confirmed
    case notNeeded = "notneeded"
}

struct SeedNotifyDTO: Codable {
    let status: SeedNotifyStatus
}
