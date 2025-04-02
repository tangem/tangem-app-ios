//
//  SiteScan.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension BlockaidDTO {
    enum SiteScan {
        struct Request: Encodable {
            let url: String
        }

        struct Response: Decodable {
            let status: Status
            let url: String
            let isMalicious: Bool

            enum Status: String, Decodable {
                case hit
                case miss
            }
        }
    }
}
