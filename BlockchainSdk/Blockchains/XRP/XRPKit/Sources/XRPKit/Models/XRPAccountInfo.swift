//
//  XRPAccountInfo.swift
//  BigInt
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation

public struct XRPAccountInfo: Codable {
    public var address: String
    public var drops: Int
    public var sequence: Int
}
