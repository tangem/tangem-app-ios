//
//  TangemBaseAPIError.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct TangemBaseAPIError: Decodable {
    let error: TangemAPIError
}
