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
    
    public func mapOptional<T>(_ tag: TlvTag) throws -> T? {
        do {
            let mapped: T = try map(tag)
            return mapped
        } catch TlvMapperError.missingTag {
            return nil
        }
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
            guard String.self == T.self else {
                print("Mapping error. Type for tag: \(tag) must be String")
                throw TlvMapperError.wrongType
            }
            
            let hexString = tagValue.toHexString()
            return hexString as! T
        case .utf8String:
            guard String.self == T.self else {
                print("Mapping error. Type for tag: \(tag) must be String")
                throw TlvMapperError.wrongType
            }
            
            guard let utfValue = tagValue.toUtf8String() else {
                print("Mapping error. Failed convert \(tag) to utf8 string")
                throw TlvMapperError.convertError
            }
            
            return utfValue as! T
        case .intValue:
            guard Int.self == T.self else {
                print("Mapping error. Type for tag: \(tag) must be Int")
                throw TlvMapperError.wrongType
            }
            
            guard let intValue = tagValue.toInt() else {
                print("Mapping error. Failed convert \(tag) to int")
                throw TlvMapperError.convertError
            }
            
            return intValue as! T
        case .data:
            guard Data.self == T.self else {
                print("Mapping error. Type for tag: \(tag) must be Data")
                throw TlvMapperError.wrongType
            }
            
            return tagValue as! T
        case .ellipticCurve:
            guard EllipticCurve.self == T.self else {
                print("Mapping error. Type for tag: \(tag) must be EllipticCurve")
                throw TlvMapperError.wrongType
            }
            
            guard let utfValue = tagValue.toUtf8String(),
                let curve = EllipticCurve(rawValue: utfValue) else {
                    print("Mapping error. Failed convert \(tag) to utfValue and curve")
                    throw TlvMapperError.convertError
            }
            
            return curve as! T
        case .boolValue:
            return true as! T
        case .dateTime:
            guard String.self == T.self else {
                print("Mapping error. Type for tag: \(tag) must be String")
                throw TlvMapperError.wrongType
            }
            
            let dateString = tagValue.toDateString()
            return dateString as! T
            
        case .productMask:
            guard ProductMask.self == T.self else {
                print("Mapping error. Type for tag: \(tag) must be ProductMask")
                throw TlvMapperError.wrongType
            }
            
            guard let byte = tagValue.bytes.first,
                let productMask = ProductMask(rawValue: byte) else {
                    print("Mapping error. Failed convert \(tag) to productMask")
                    throw TlvMapperError.convertError
            }
            
            return productMask as! T
        case .settingsMask:
            guard SettingsMask.self == T.self else {
                print("Mapping error. Type for tag: \(tag) must be SettingsMask")
                throw TlvMapperError.wrongType
            }
            
            guard let intValue = tagValue.toInt() else {
                print("Mapping error. Failed convert \(tag) to int")
                throw TlvMapperError.convertError
            }
            
            let settingsMask = SettingsMask(rawValue: intValue)
            return settingsMask as! T
        case .cardStatus:
            guard CardStatus.self == T.self else {
                print("Mapping error. Type for tag: \(tag) must be CardStatus")
                throw TlvMapperError.wrongType
            }
            
            guard let intValue = tagValue.toInt(),
                let cardStatus = CardStatus(rawValue: intValue) else {
                    print("Mapping error. Failed convert \(tag) to int and CardStatus")
                    throw TlvMapperError.convertError
            }
            
            return cardStatus as! T
        case .signingMethod:
            guard SigningMethod.self == T.self else {
                print("Mapping error. Type for tag: \(tag) must be SigningMethod")
                throw TlvMapperError.wrongType
            }
            
            guard let intValue = tagValue.toInt(),
                let signingMethod = SigningMethod(rawValue: intValue) else {
                    print("Mapping error. Failed convert \(tag) to int and SigningMethod")
                    throw TlvMapperError.convertError
            }
            
            return signingMethod as! T
        }
    }
}
