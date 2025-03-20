//
//  APIListDTO.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

typealias APIListDTO = [String: [APIInfoDTO]]

struct APIInfoDTO: Decodable {
    let type: String
    let name: String?
    let url: String?
}
