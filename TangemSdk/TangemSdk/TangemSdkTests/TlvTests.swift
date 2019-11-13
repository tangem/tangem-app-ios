//
//  TlvTests.swift
//  TangemSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import XCTest
import CoreNFC
@testable import TangemSdk

class TlvTests: XCTestCase {
    func testTlvSerialization() {
        let testData = Data(hex: "0105000000000050020101")
        let tlv1 = Tlv(TlvTag.cardId, value: Data(repeating: UInt8(0), count: 5))
        let tlv2 = Tlv(tagRaw: Byte(0x50), value: Data(repeating: UInt8(1), count: 2))
        let tlvArray = [tlv1, tlv2]
        let serialized = tlvArray.serialize()
        XCTAssertEqual(serialized, testData)
        
        let tlv3 = Tlv(tagRaw: 0x69, value: Data())
        XCTAssertEqual(tlv3.tag, TlvTag.unknown)
        
        let tlvLong = Tlv(.cardPublicKey, value: Data(repeating: UInt8(0), count: 255))
        let tlvLongData = tlvLong.serialize()
        XCTAssertEqual(tlvLongData.count, 259)
    }
    
    func testTlvDeserialization() {
        let testData = Data(hex: "010500000000005002010110FF000A00000000000000000000")
        let deserialized = Array<Tlv>.init(testData)
        XCTAssertNotNil(deserialized)
        
        let tlv1 = Tlv(TlvTag.cardId, value: Data(repeating: UInt8(0), count: 5))
        let tlv2 = Tlv(tagRaw: Byte(0x50), value: Data(repeating: UInt8(1), count: 2))
        let tlv3 = Tlv(.pin, value: Data(repeating: UInt8(0), count: 10))
        let tlvArray = [tlv1, tlv2, tlv3]
        
        XCTAssertTrue(deserialized!.contains(tag: .cardId))
        XCTAssertEqual(deserialized!, tlvArray)
        
        XCTAssertNotNil(Array<Tlv>.init(Data()))
        
        let testBadData = Data(hex: "10FF000A000000")
        XCTAssertNil(Array<Tlv>.init(testBadData))
        
        let testBadData1 = Data(hex: "10FF00")
        XCTAssertNil(Array<Tlv>.init(testBadData1))
        
        let testBadData2 = Data(hex: "10")
        XCTAssertNil(Array<Tlv>.init(testBadData2))
        
        XCTAssertNotNil(Array<Tlv>.init( Data(hex: "1000")))
    }
    
    func testMapping() {
        let testData = Data(hex: "0108FF00000000000111200B534D415254204341534800020102800A312E3238642053444B000341044CB1004B43B407419E29A8FFDB64D4E54B623CEB37F3C2037B3ED6F38EEE0C1F2E5AB5D015DF78FE15EFA5327F59A24C059C999AFC1D3F2A8DDEEE16467CA75F0A027E310C5E8102FFFF820407E2071B830B54414E47454D2053444B00840342544386405D7FFCE7446DAA9084595F383E712A63B2AC4CF7BDE7673F05D6FC629F0D3E0F637910B5A675F66B633331630AEFB614345AF05208DEECF2274FF3B44642AC883041045F16BD1D2EAFE463E62A335A09E6B2BBCBD04452526885CB679FC4D27AF1BD22F553C7DEEFB54FD3D4F361D14E6DC3F11B7D4EA183250A60720EBDF9E110CD26050A736563703235366B3100080400000064070100090205DC604104B45FF0D628E1B59F7AEFA1D5B45AB9D7C47FC090D8B29ACCB515431BDBAD2802DDB3AC5E83A06BD8F13ABB84A465CA3C0FA0B44301F80295A9B4C5E35D5FDFE56204000000646304000000000F01009000")
        
        let tlv = Tlv.deserialize(testData)!
        let mapper = TlvMapper(tlv: tlv)
        let optinalHexString: String? = try? mapper.map(.cardId)
        XCTAssertNotNil(optinalHexString)
        
        let hexString: String = try! mapper.map(.cardId)
        XCTAssertNotNil(hexString)
        
        let optionalParameter: String? = try! mapper.mapOptional(.manufacturerName)
        XCTAssertNotNil(optionalParameter)
        
        let missing: String? = try! mapper.mapOptional(.tokenSymbol)
        XCTAssertNil(missing)
        
        do {
            let _: String = try mapper.map(.isActivated)
            XCTAssertTrue(false)
        } catch {
            XCTAssertTrue(true)
        }
        
        do {
            let _: String? = try mapper.mapOptional(.isActivated)
            XCTAssertTrue(false)
        } catch {
            XCTAssertTrue(true)
        }
        
        let falseBool: Bool = try! mapper.map(.isLinked)
        XCTAssertFalse(falseBool)
        
        do {
            let _: String = try mapper.map(.blockchainName)
            XCTAssertTrue(false)
        } catch {
            XCTAssertTrue(true)
        }
    }
}
