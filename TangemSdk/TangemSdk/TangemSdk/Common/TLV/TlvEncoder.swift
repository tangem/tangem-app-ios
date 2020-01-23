//
//  TlvEncoder.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public final class TlvEncoder {
    public func encode<T>(_ tag: TlvTag, value: T) throws -> Tlv {
        switch tag.valueType {
        case .hexString:
            try typeCheck(value, String.self)
            if tag == .pin || tag == .pin2 {
                return Tlv(tag, value: (value as! String).sha256())
            } else {
                return Tlv(tag, value: Data(hexString: value as! String))
            }
        case .utf8String:
            fatalError("not implemented")
        case .byte:
            try typeCheck(value, Int.self)
            return Tlv(tag, value: (value as! Int).byte)
        case .intValue:
            try typeCheck(value, Int.self)
            return Tlv(tag, value: (value as! Int).bytes4)
        case .boolValue:
            fatalError("not implemented")
        case .data:
            try typeCheck(value, Data.self)
            return Tlv(tag, value: value as! Data)
        case .ellipticCurve:
            fatalError("not implemented")
        case .dateTime:
            fatalError("not implemented")
        case .productMask:
            fatalError("not implemented")
        case .settingsMask:
            fatalError("not implemented")
        case .cardStatus:
            fatalError("not implemented")
        case .signingMethod:
            fatalError("not implemented")
        }
    }
    
    private func typeCheck<FromType, ToType>(_ value: FromType, _ to: ToType) throws {
        guard value is ToType else {
            print("Encoding error. Value is \(FromType.self). Expected: \(ToType.self)")
            throw TaskError.serializeCommandError
        }
    }
}
