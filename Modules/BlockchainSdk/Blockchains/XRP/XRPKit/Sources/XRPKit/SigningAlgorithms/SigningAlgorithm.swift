//
//  File.swift
//
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation

protocol SigningAlgorithm {
    static func deriveKeyPair(seed: [UInt8]) throws -> XRPKeyPair
    static func sign(message: [UInt8], privateKey: [UInt8]) throws -> [UInt8]
    static func verify(signature: [UInt8], message: [UInt8], publicKey: [UInt8]) throws -> Bool
}
