//
//  ExpressKeys.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct ExpressKeys: Decodable {
    let apiKey: String
    let signVerifierPublicKey: String
}
