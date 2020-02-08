////
////  ResponseApdu.swift
////  TangemKit
////
////  Created by [REDACTED_AUTHOR]
////  Copyright © 2019 Smart Cash AG. All rights reserved.
////
//
//import Foundation
//
//public struct ResponseApdu {
//    private let sw1: UInt8
//    private let sw2: UInt8
//    
//    public let tlv: [CardTag:CardTLV]
//    
//    public var state: CardSW? {
//        let sw1Byte = UInt16(sw1)
//        let sw2Byte = UInt16(sw2)
//        let swByte = UInt16( (sw1Byte << 8) | sw2Byte)
//        return CardSW(rawValue: swByte)
//    }
//    
////    public init(with bytes: [UInt8]) throws {
////        guard bytes.count >= 2 else {
////            throw TangemException.wrongResponseApdu(description: Constants.invalidLength)
////        }
////
////        if bytes.count == 2 {
////            tlv = [:]
////        } else {
////            let bodyData = Array(bytes.prefix(bytes.count-2))
////             let commonTlv = Dictionary.init(with: bodyData)
////                  if let cardData = commonTlv[.cardData]?.value {
////                      let cardDataTlv = Dictionary.init(with: cardData)
////                      tlv = commonTlv.merging(cardDataTlv, uniquingKeysWith: { (_, new) -> CardTLV in new })
////                  } else {
////                      tlv = commonTlv
////                  }
////        }
////
////        sw1 = 0x00FF & bytes[bytes.count - 2]
////        sw2 = 0x00FF & bytes[bytes.count - 1]
////    }
//    
//    public init(with data: Data, sw1: UInt8, sw2: UInt8) {
//        self.sw1 = sw1
//        self.sw2 = sw2
//        let dataBytes = [UInt8](data)
//        
//        let commonTlv = Dictionary.init(with: dataBytes)
//        if let cardData = commonTlv[.cardData]?.value {
//            let cardDataTlv = Dictionary.init(with: cardData)
//            tlv = commonTlv.merging(cardDataTlv, uniquingKeysWith: { (_, new) -> CardTLV in new })
//        } else {
//            tlv = commonTlv
//        }
//    }
//
//}
//
////Mark: Constants
//
//extension ResponseApdu {
//    fileprivate struct Constants {
//        static let invalidLength: String = "Response length must be greater then 2"
//    }
//}
