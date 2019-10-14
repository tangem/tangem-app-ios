//
//  TlvMapper.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

enum TlvMapperError: Error {
    case missingTag
    case wrongType
    case convertError
}

public final class TlvMapper {
    let tlv: [Tlv]
    
    public init(tlv: [Tlv]) {
        self.tlv = tlv
    }
    
    public func map<T>(_ tag: TlvTag) throws -> T {
        guard let tagValue = tlv.value(for: tag) else {
            if tag.valueType == .boolValue {
                return false as! T
            }
            
            throw TlvMapperError.missingTag
        }
        
        switch tag.valueType {
        case .hexString:
            let hexString = tagValue.toHexString()
            guard String.self == T.self else {
                throw TlvMapperError.wrongType
            }
            
            return hexString as! T
        case .utf8String:
            guard let utfValue = tagValue.toUtf8String() else {
                throw TlvMapperError.convertError
            }
            
            guard String.self == T.self else {
                throw TlvMapperError.wrongType
            }
            
            return utfValue as! T
        case .intValue:
            guard let intValue = tagValue.toInt() else {
                throw TlvMapperError.convertError
            }
            
            guard Int.self == T.self else {
                throw TlvMapperError.wrongType
            }
            
            return intValue as! T
        case .data:
            guard Data.self == T.self else {
                throw TlvMapperError.wrongType
            }
            
            return tagValue as! T
        case .ellipticCurve:
            guard EllipticCurve.self == T.self else {
                throw TlvMapperError.wrongType
            }
            
            guard let utfValue = tagValue.toUtf8String(),
                let curve = EllipticCurve(rawValue: utfValue)else {
                    throw TlvMapperError.convertError
            }
            
            return curve as! T
        case .boolValue:
            return true as! T
        }
        
    }
}
