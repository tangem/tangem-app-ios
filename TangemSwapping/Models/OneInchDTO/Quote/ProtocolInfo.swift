//
//  ProtocolInfo.swift
//  TangemSwapping
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public struct ProtocolInfo: Decodable {
    public let name: String
    public let part: Int
    public let fromTokenAddress: String
    public let toTokenAddress: String
}
