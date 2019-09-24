//
//  MemoProtocol.swift
//  stellarsdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public protocol MemoProtocol {
    func toXDR() -> MemoXDR
    init?(text:String) throws
    init?(hash:Data) throws
    init?(returnHash:Data) throws
    func type() -> String
}

public protocol MemoHashProtocol {
    func hexValue() throws -> String
    func trimmedHexValue() throws -> String
}
