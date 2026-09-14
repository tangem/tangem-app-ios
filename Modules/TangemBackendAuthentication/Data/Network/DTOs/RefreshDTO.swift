//
//  RefreshDTO.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

/// `POST api/authentication/v1/mobile/token/refresh`
enum RefreshDTO {
    struct Request: Encodable {
        let refreshToken: String
    }
}
