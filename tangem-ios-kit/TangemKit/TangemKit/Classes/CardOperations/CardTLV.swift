////
////  CardTLV.swift
////  TangemKit
////
////  Created by [REDACTED_AUTHOR]
////
//import CryptoSwift
//
//public struct CardTLV {
//    public let tag: CardTag
//    public let value: [UInt8]?
//    
//    var bytes: [UInt8] { 
//        var bytes = [UInt8]()
//        let length = value?.count ?? 0
//        bytes.reserveCapacity(1 + length)
//        
//        bytes.append(tag.rawValue)
//        
//        if let value = value {
//            if length > 0xFE {
//                bytes.append(0xFF)
//                bytes.append(contentsOf: length.tlvBytes)
//            } else {
//                let lengthAsByte = length.byte
//                bytes.append(lengthAsByte)
//            }
//            bytes.append(contentsOf: value)
//        } else {
//            bytes.append(0x00)
//        }
//        
//        return bytes
//    }
//    
//    public init (_ tag: CardTag, value: [UInt8]? ) {
//        self.tag = tag
//        self.value = value
//    }
//}
