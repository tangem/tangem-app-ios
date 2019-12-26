//
//  DerivationNode.swift
//  CryptoSwift
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation

public enum DerivationNode {
    case hardened(UInt32)
    case notHardened(UInt32)
    
    public var index: UInt32 {
        switch self {
        case .hardened(let index):
            return index
        case .notHardened(let index):
            return index
        }
    }
    
    public var hardens: Bool {
        switch self {
        case .hardened:
            return true
        case .notHardened:
            return false
        }
    }
}
