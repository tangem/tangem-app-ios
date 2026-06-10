//
//  ExpressCurrency.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public struct ExpressCurrency: Hashable, Codable {
    public let contractAddress: String
    public let network: String
}
