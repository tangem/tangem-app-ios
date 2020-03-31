//
//  TlvDecoder.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
/// Maps value fields in `Tlv` from raw bytes to concrete classes
/// according to their `TlvTag` and corresponding `TlvValueType`.
public final class TlvDecoder {
    let tlv: [Tlv]
    
    /// Initializer
    /// - Parameter tlv: array of TLVs, which values are to be converted to particular classes.
    public init(tlv: [Tlv]) {
        self.tlv = tlv
    }
    
    /**
     * Finds `Tlv` by its `TlvTag`.
     * Returns nil if `Tlv` is not found, otherwise converts its value to `T`.
     *
     * - Parameter tag: `TlvTag` of a `Tlv` which value is to be returned.
     *
     * - Returns: Value converted to an optional type `T`.
     */
    public func decodeOptional<T>(_ tag: TlvTag) throws -> T? {
        do {
            let mapped: T = try innerDecode(tag, asOptional: true)
            return mapped
        } catch SessionError.decodeFailedMissingTag {
            return nil
        }
    }
    
    /**
     * Finds `Tlv` by its `TlvTag`.
     * Throws `TlvMapperError.missingTag` if `Tlv` is not found,
     * otherwise converts `Tlv` value to `T`. Can throw any of a `TlvMapperError`
     *
     * - Parameter tag: `TlvTag` of a `Tlv` which value is to be returned.
     *
     * - Returns: Value converted to a type `T`.  You can use try? and map to optional type `T?` without exception handling
     *
     */
    public func decode<T>(_ tag: TlvTag) throws -> T {
        return try innerDecode(tag, asOptional: false)
    }
    
    
    private func innerDecode<T>(_ tag: TlvTag, asOptional: Bool) throws -> T {
        guard let tagValue = tlv.value(for: tag) else {
            if tag.valueType == .boolValue {
                guard Bool.self == T.self || Bool?.self == T.self else {
                    print("Mapping error. Type for tag: \(tag) must be Bool")
                    throw SessionError.decodeFailedTypeMismatch
                }
                
                return false as! T
            }
            if !asOptional {
                print("Mapping error. Missing tag: \(tag)")
            }
            
            throw SessionError.decodeFailedMissingTag
        }
        
        switch tag.valueType {
        case .hexString:
            guard String.self == T.self || String?.self == T.self else {
                print("Mapping error. Type for tag: \(tag) must be String")
                throw SessionError.decodeFailedTypeMismatch
            }
            
            let hexString = tagValue.asHexString()
            return hexString as! T
        case .utf8String:
            guard String.self == T.self || String?.self == T.self else {
                print("Mapping error. Type for tag: \(tag) must be String")
                throw SessionError.decodeFailedTypeMismatch
            }
            
            guard let utfValue = tagValue.toUtf8String() else {
                print("Mapping error. Failed convert \(tag) to utf8 string")
                throw SessionError.decodeFailed
            }
            
            return utfValue as! T
        case .intValue, .byte, .uint16:
            guard Int.self == T.self || Int?.self == T.self else {
                print("Mapping error. Type for tag: \(tag) must be Int")
                throw SessionError.decodeFailedTypeMismatch
            }
            
            let intValue = tagValue.toInt()
            return intValue as! T
        case .data:
            guard Data.self == T.self || Data?.self == T.self else {
                print("Mapping error. Type for tag: \(tag) must be Data")
                throw SessionError.decodeFailedTypeMismatch
            }
            
            return tagValue as! T
        case .ellipticCurve:
            guard EllipticCurve.self == T.self || EllipticCurve?.self == T.self else {
                print("Mapping error. Type for tag: \(tag) must be EllipticCurve")
                throw SessionError.decodeFailedTypeMismatch
            }
            
            guard let utfValue = tagValue.toUtf8String(),
                let curve = EllipticCurve(rawValue: utfValue) else {
                    print("Mapping error. Failed convert \(tag) to utfValue and curve")
                    throw SessionError.decodeFailed
            }
            
            return curve as! T
        case .boolValue:
            guard Bool.self == T.self || Bool?.self == T.self else {
                print("Mapping error. Type for tag: \(tag) must be Bool")
                throw SessionError.decodeFailedTypeMismatch
            }
            
            return true as! T
        case .dateTime:
            guard Date.self == T.self || Date?.self == T.self else {
                print("Mapping error. Type for tag: \(tag) must be Date")
                throw SessionError.decodeFailedTypeMismatch
            }
            
            guard let date = tagValue.toDate() else {
                print("Mapping error. Failed convert \(tag) to date")
                throw SessionError.decodeFailed
            }
            
            return date as! T
            
        case .productMask:
            guard ProductMask.self == T.self || ProductMask?.self == T.self else {
                print("Mapping error. Type for tag: \(tag) must be ProductMask")
                throw SessionError.decodeFailedTypeMismatch
            }
            
            guard let byte = tagValue.toBytes.first else {
                    print("Mapping error. Failed convert \(tag) to ProductMask")
                    throw SessionError.decodeFailed
            }
            let productMask = ProductMask(rawValue: byte)
            return productMask as! T
        case .settingsMask:
            guard SettingsMask.self == T.self || SettingsMask?.self == T.self else {
                print("Mapping error. Type for tag: \(tag) must be SettingsMask")
                throw SessionError.decodeFailedTypeMismatch
            }
            
            let intValue = tagValue.toInt()
            let settingsMask = SettingsMask(rawValue: intValue)
            return settingsMask as! T
        case .cardStatus:
            guard CardStatus.self == T.self || CardStatus?.self == T.self else {
                print("Mapping error. Type for tag: \(tag) must be CardStatus")
                throw SessionError.decodeFailedTypeMismatch
            }
            let intValue = tagValue.toInt()
            guard let cardStatus = CardStatus(rawValue: intValue) else {
                print("Mapping error. Failed convert \(tag) to int and CardStatus")
                throw SessionError.decodeFailed
            }
            
            return cardStatus as! T
        case .signingMethod:
            guard SigningMethod.self == T.self || SigningMethod?.self == T.self else {
                print("Mapping error. Type for tag: \(tag) must be SigningMethod")
                throw SessionError.decodeFailedTypeMismatch
            }
            
            let intValue = tagValue.toInt()
            let signingMethod = SigningMethod(rawValue: intValue)
            return signingMethod as! T
        case .issuerExtraDataMode:
            guard IssuerExtraDataMode.self == T.self || IssuerExtraDataMode?.self == T.self else {
                print("Mapping error. Type for tag: \(tag) must be IssuerExtraDataMode")
                throw SessionError.decodeFailedTypeMismatch
            }
            
            guard let byte = tagValue.toBytes.first,
                let mode = IssuerExtraDataMode(rawValue: byte) else {
                    print("Mapping error. Failed convert \(tag) to IssuerExtraDataMode")
                    throw SessionError.decodeFailed
            }
            
            return mode as! T
        }
    }
}
