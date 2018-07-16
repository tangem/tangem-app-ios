//
//  TLV.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Yulia Moskaleva. All rights reserved.
//

import Foundation

enum TLVError: Error{
    
    case wrongTLV
    
}

struct TLVTag {
    
    let name: String
    let address: UInt8
    let length: Int
    let isString: Bool
    
    init(name: String, address: UInt8, length: Int = 0, isString: Bool = false) {
        self.name = name
        self.address = address
        self.length = length
        self.isString = isString
    }
    
}

public class TLV : NSObject {
    
    public var tagName = ""
    public var tagCode: UInt8 = 0x00
    public var tagHexStringCode = ""
    
    public var tagLength: UInt16 = 0
    
    public var hexBinaryValues = [UInt8]()
    public var hexStringValue = ""
    public var stringValue = ""
    
    let tagsInfo: [TLVTag] = {
        var tags = [TLVTag]()
        
        tags.append(TLVTag(name: "CardID", address: 0x01, length: 8))
        tags.append(TLVTag(name: "Firmware", address: 0x80, isString: true))
        tags.append(TLVTag(name: "SettingsMask", address: 0x0A, length: 2))
        tags.append(TLVTag(name: "Card_Data", address: 0x0C, length: 512))
        tags.append(TLVTag(name: "Batch_ID", address: 0x81, length: 2))
        tags.append(TLVTag(name: "Manufacture_Date_Time", address: 0x82, length: 4))
        tags.append(TLVTag(name: "Issuer_Name", address: 0x83, isString: true))
        tags.append(TLVTag(name: "Blockchain_Name", address: 0x84, isString: true))
        tags.append(TLVTag(name: "Token_Symbol", address: 0xA0, isString: true))
        tags.append(TLVTag(name: "Token_Contract_Address", address: 0xA1, isString: true))
        tags.append(TLVTag(name: "Token_Decimal", address: 0xA2, length: 1))
        tags.append(TLVTag(name: "Manufacturer_Signature", address: 0x86, length: 64))
        tags.append(TLVTag(name: "Card_PublicKey", address: 0x03, length: 65))
        tags.append(TLVTag(name: "Wallet_PublicKey", address: 0x60, length: 65))
        tags.append(TLVTag(name: "MaxSignatures", address: 0x08, length: 4))
        tags.append(TLVTag(name: "RemainingSignatures", address: 0x62, length: 4))
        tags.append(TLVTag(name: "SignedHashes", address: 0x63, length: 4))
        tags.append(TLVTag(name: "Challenge", address: 0x16, length: 16))
        tags.append(TLVTag(name: "Salt", address: 0x17, length: 16))
        tags.append(TLVTag(name: "Wallet_Signature", address: 0x61, length: 64))
        tags.append(TLVTag(name: "Health", address: 0x0F, length: 1))
        
        return tags
    }()
    
    public init(data: [UInt8], _ offset: inout Int) throws {
        super.init()
        
        guard let ltvTag = self.getTLVTagInfo(data, &offset) else {
            assertionFailure("Didn't found a tag with code \(self.tagHexStringCode)")
            return
        }
        print("0x\(ltvTag.address.toAsciiHex()): \(ltvTag.name)")
        
        self.tagName = ltvTag.name
        
        guard let tagLength = self.getTagLength(data, &offset) else {
            throw TLVError.wrongTLV
        }
        
        self.tagLength = tagLength
        
        let end = offset + Int(tagLength)
        guard end <= data.count else {
            throw TLVError.wrongTLV
        }
        
        self.hexBinaryValues = Array(data[offset...end-1])
        self.hexStringValue = valueToHex()
        
        if ltvTag.isString {
            self.stringValue = valueToUTF8()
        }
        
        if self.tagName == "CardID" {
            self.stringValue = getCardID()
        }
        
        if self.tagName == "Manufacture_Date_Time" {
            self.stringValue = getManufactureDate()
        }
        
        if self.tagName == "Batch_ID" {
            self.stringValue = getBatchID()
        }
        
        if self.tagName == "RemainingSignatures" {
            self.stringValue = getRemainingSignatures()
        }
        
        offset = end
    }
    
    func getTLVTagInfo(_ data:[UInt8], _ offset: inout Int) -> TLVTag? {
        let tagCode: UInt8 = data[offset]
        self.tagCode = tagCode
        self.tagHexStringCode = tagCode.toAsciiHex()
        offset += 1
        
        return self.tagsInfo.first(where: { (tag) -> Bool in
            return tag.address == tagCode
        })
    }
    
    private func getRemainingSignatures()->String{
        return "\(UInt32(strtoul(self.hexStringValue, nil, 16)))"
    }
    
    private func getBatchID()->String{
        return "\(UInt64(strtoul(self.hexStringValue, nil, 16)))"
    }
    
    private func getManufactureDate()->String{
        let hexYear = self.hexBinaryValues[0].toAsciiHex() + self.hexBinaryValues[1].toAsciiHex()
        
        //Hex -> Int16
        let year = UInt16(hexYear.withCString{strtoul($0,nil,16)})
        var mm = ""
        var dd = ""
        
        if (self.hexBinaryValues[2] < 10) {
            mm = "0" + "\(self.hexBinaryValues[2])"
        } else {
            mm = "\(self.hexBinaryValues[2])"
        }
        
        if (self.hexBinaryValues[3] < 10) {
            dd = "0" + "\(self.hexBinaryValues[3])"
        } else {
            dd = "\(self.hexBinaryValues[3])"
        }
        
        let components = DateComponents(year:Int(year), month:Int(self.hexBinaryValues[2]),day:Int(self.hexBinaryValues[3]))
        let calendar = Calendar(identifier: .gregorian)
        let date = calendar.date(from: components)
        
        let manFormatter = DateFormatter()
        manFormatter.dateStyle = DateFormatter.Style.medium
        if let date = date {
            let dateString = manFormatter.string(from: date)
            return dateString
        }
        
        return "\(year)" + "." + mm + "." + dd
    }
    
    private func valueToHex() -> String{
        var valueStr = ""
        for byte in self.hexBinaryValues{
            valueStr += byte.toAsciiHex()
        }
        return valueStr
    }
    
    private func valueToUTF8() -> String{
        let data = dataWithHexString(hex: self.hexStringValue)
        return String(data: data, encoding: .utf8) ?? ""
    }
    
    private func getCardID() -> String {
        guard self.hexBinaryValues.count == 8 else {
            return ""
        }

        var result = ""
        var counter = 0
        for byte in self.hexBinaryValues {
            counter += 1
            result += byte.toAsciiHex()
            if counter == 2 || counter == 4 || counter == 6 {
                result += " "
            }
        }
        return result
    }
    
    private func getTagLength(_ data:[UInt8], _ offset: inout Int) -> UInt16? {
        var tagArray = [UInt8]()
        if offset >= data.count - 1 {
            return nil
        }
        
        if (data[offset] == 0xFF) {
            if offset >= data.count - 1 {
                return nil
            }
            
            offset += 1
            tagArray.append(data[offset])
            offset += 1
            tagArray.append(data[offset])
        } else {
            tagArray.append(data[offset])
        }
        offset += 1
        return arrayToUInt16(tagArray);
    }
    
    public static func checkPIN(_ data:[UInt8], _ offset: inout Int) -> Bool? {
        var tagArray:[UInt8] = [UInt8]()
        let checkOK: UInt16 = 0x9000
        let checkPIN: UInt16 = 0x6A86
        
        tagArray.append(data[offset])
        offset += 1
        tagArray.append(data[offset])
        offset += 1
        
        if let twoFirstBytes = arrayToUInt16(tagArray){
            if (twoFirstBytes == checkOK) {
                return true
            }
            if (twoFirstBytes == checkPIN) {
                return nil
            }
        }
        return nil
    }
}
