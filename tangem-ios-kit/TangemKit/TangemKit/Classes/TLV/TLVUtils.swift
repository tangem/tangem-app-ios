//
//  TLVUtils.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Smart Cash AG. All rights reserved.
//

import Foundation
import UIKit
import CommonCrypto

func bytesUsed(_ value: UInt64) -> UInt8 {
    let array = value.toByteArray()
    return UInt8(array.filter({ $0 > 0 }).count)
}

func getLengthData(_ length: Int) -> [UInt8] {
    guard length > 127 else {
        return [length.toByteArray().last!]
    }

    var result = [UInt8]()
    let byteCount = bytesUsed(UInt64(length))
    let lengthsLength: UInt8 = 0x80 | byteCount
    result.append(lengthsLength)
    let lengthArray = length.toByteArray()

    lengthArray
        .filter({ $0 > 0 })
        .forEach({ result.append($0) })

    return result
}

func arrayToUInt64(_ data: [UInt8]) -> UInt64? {
    if data.count > 8 {
        return nil
    }
    let temp = NSData(bytes: data.reversed(), length: data.count)

    let rawPointer = UnsafeRawPointer(temp.bytes)
    let pointer = rawPointer.assumingMemoryBound(to: UInt64.self)
    let value = pointer.pointee

    return value
}

func arrayToDecimalNumber(_ data: [UInt8]) -> NSDecimalNumber? {
    let reversed = data.reversed()
    var number = NSDecimalNumber(value: 0)

    reversed.enumerated().forEach { (arg) in
        let (offset, value) = arg
        number = number.adding(NSDecimalNumber(value: value).multiplying(by: NSDecimalNumber(value: 256).raising(toPower: offset)))
    }

    return number
}

func arrayToUInt32(_ data: [UInt8]) -> UInt32? {
    if data.count > 4 {
        return nil
    }
    let temp = NSData(bytes: data.reversed(), length: data.count)
    let rawPointer = UnsafeRawPointer(temp.bytes)
    let pointer = rawPointer.assumingMemoryBound(to: UInt32.self)
    let value = pointer.pointee
    return value
}

func cleanHex(hexStr: String) -> String {
    return hexStr.trimmingCharacters(in: NSCharacterSet(charactersIn: "<> ") as CharacterSet).replacingOccurrences(of: " ", with: "")
}

public func isValidHex(_ asciiHex: String) -> Bool {
    let regex = try! NSRegularExpression(pattern: "^[0-9a-f]*$", options: .caseInsensitive)

    let found = regex.firstMatch(in: asciiHex, options: [], range: NSRange(location: 0, length: asciiHex.count))

    if found == nil || found?.range.location == NSNotFound || asciiHex.count % 2 != 0 {
        return false
    }

    return true
}

public func dataWithHexString(hex: String) -> Data {
    var hex = hex
    var data = Data()
    while hex.count > 0 {
        let c = String(hex[..<hex.index(hex.startIndex, offsetBy: 2)])
        hex = String(hex[hex.index(hex.startIndex, offsetBy: 2)...])
        var ch: UInt32 = 0
        Scanner(string: c).scanHexInt32(&ch)
        var char = UInt8(ch)
        data.append(&char, count: 1)
    }

    return data
}

func arrayToUInt16(_ data: [UInt8]) -> UInt16? {
    if data.count > 2 {
        return nil
    }

    let data = NSData(bytes: data.reversed(), length: data.count)
    let rawPointer = UnsafeRawPointer(data.bytes)
    let pointer = rawPointer.assumingMemoryBound(to: UInt16.self)
    let value = pointer.pointee

    return value
}

func sha256(_ data: Data) -> Data? {
    guard let res = NSMutableData(length: Int(CC_SHA256_DIGEST_LENGTH)) else {
        return nil
    }

    CC_SHA256((data as NSData).bytes, CC_LONG(data.count), res.mutableBytes.assumingMemoryBound(to: UInt8.self))
    return res as Data
}

func sha256(_ str: String) -> String? {
    guard
        let data = str.data(using: String.Encoding.utf8),
        let shaData = sha256(data)
        else { return nil }
    
    return shaData.base64EncodedString(options: [])
}


func sha256(_ image: UIImage) -> String? {
    guard let data = image.cgImage?.dataProvider?.data as Data?,
        let shaData = sha256(data) else { 
            return nil
    }
    
    return shaData.base64EncodedString(options: [])
}

func randomNode() -> String {
    let nodes = ["electrum.anduck.net:50001",
                 "electrum-server.ninja:50001",
                 "btc.cihar.com:50001",
                 "vps.hsmiths.com:50001",
                 "electrum.hsmiths.com:50001",
                 "electrum.vom-stausee.de:50001",
                 "node.ispol.sk:50001",
                 "electrum2.eff.ro:50001",
                 "electrumx.nmdps.net:50001",
                 "kirsche.emzy.de:50001",
                 "electrum.petrkr.net:50001",
                 "electrum.dk:50001"]

    let rundomNumber = randRange(lower: 0, upper: nodes.count - 1)
    return nodes[rundomNumber]
}

func randRange (lower: Int, upper: Int) -> Int {
    return lower + Int(arc4random_uniform(UInt32(upper - lower + 1)))
}

func checkRibbonCase(_ card: CardViewModel) -> Int {

    let firmware = card.firmware
    let hashed = card.signedHashes
    let floatConst: Float = 1.19

    if firmware == "Not available" {
        return 0
    }

    if firmware.containsIgnoringCase(find: "d") {
       // print("RIBBON CASE ONE")
        return 1
    }
    if firmware.containsIgnoringCase(find: "r") && hashed == "" {
        //print("RIBBON CASE TWO")
        return 2
    }
    if firmware.containsIgnoringCase(find: "r") && hashed != "" {
       // print("RIBBON CASE THREE")
        return 3
    }

    if firmware.count > 3 {
        let floatString = firmware.prefix(4)
        let floatValue = (floatString as NSString).floatValue
        if floatValue < floatConst {
            //print("RIBBON CASE FOUR")
            return 4
        }
    }

    return 0
}
