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


public class TLV : NSObject {
    public var name = ""
    public var tagTLV:UInt8 = 0x00
    public var lengthTLV: UInt16 = 0
    public var valueTLV:[UInt8] = [UInt8]()
    public var tagTLVHex = ""
    public var readyValue = ""
    public var valueHex = ""
    
    public init(data:[UInt8], _ offset: inout Int) throws {
        super.init()
        self.name = self.getTagName(data,&offset)
        guard  let lenTLV = self.getTagLength(data,&offset) else {
            throw TLVError.wrongTLV
        }
        self.lengthTLV = lenTLV
        
        
        let end = offset + Int(lenTLV)
        guard end <= data.count else {
            throw TLVError.wrongTLV
        }
        self.valueTLV = Array(data[offset...end-1])
        self.valueHex = valueToHex()
        if self.name == "CardID" {
            self.readyValue = getCardID()
        }
        if self.name == "Firmware" || self.name == "Blockchain_Name" || self.name == "Issuer_Name" {
            self.readyValue = valueToUTF8()
        }
        
        if self.name == "Manufacture_Date_Time" {
            self.readyValue = getManufactureDate()
        }
        if self.name == "Batch_ID" {
            self.readyValue = getBanchID()
        }
        if self.name == "Name_85" {
            self.readyValue = valueToUTF8()
        }
        
        if self.name == "RemainingSignatures" {
            self.readyValue = getRemainingSignatures()
        }
        
        
        offset = end
    }
    
    private func getRemainingSignatures()->String{
        return "\(UInt32(strtoul(self.valueHex, nil, 16)))"
    }
    
    private func getBanchID()->String{
        return "\(UInt64(strtoul(self.valueHex, nil, 16)))"
    }
    
    private func getManufactureDate()->String{
        let hexYear = self.valueTLV[0].toAsciiHex() + self.valueTLV[1].toAsciiHex()
        //Hex -> Int16
        let year = UInt16(hexYear.withCString{strtoul($0,nil,16)})
        var mm = ""
        var dd = ""
        
        if(self.valueTLV[2] < 10) {
            mm = "0" + "\(self.valueTLV[2])"
        } else {
            mm = "\(self.valueTLV[2])"
        }
        if(self.valueTLV[3] < 10) {
            dd = "0" + "\(self.valueTLV[3])"
        } else {
            dd = "\(self.valueTLV[3])"
        }
        print("YEAR YEAR YEAR: \(year)")
        print("MONTH MONTH MONTH: \(self.valueTLV[2])")
        print("DAY DAY DAY: \(self.valueTLV[3])")
        let currentLocale = Locale.current
        let components = DateComponents(year:Int(year), month:Int(self.valueTLV[2]),day:Int(self.valueTLV[3]))
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
        for byte in self.valueTLV{
            valueStr += byte.toAsciiHex()
        }
        return valueStr
    }
    
    private func valueToUTF8() -> String{
        let data = dataWithHexString(hex: self.valueHex)
        return String(data: data, encoding: .utf8) ?? ""
    }
    
    private func getCardID() -> String{
        if self.valueTLV.count == 8 {
            var valueStr = ""
            var counter = 0
            for byte in self.valueTLV{
                counter += 1
                valueStr += byte.toAsciiHex()
                if counter == 2 || counter == 4 || counter == 6{
                    valueStr += " "
                }
            }
            return valueStr
        }
        return ""
    }
    
    private func getTagLength(_ data:[UInt8], _ offset: inout Int) -> UInt16?{
        var tagArray:[UInt8] = [UInt8]()
        if offset >= data.count - 1 { return nil}
        if(data[offset] == 0xFF){
            if offset >= data.count - 1 { return nil}
            offset += 1
            tagArray.append(data[offset])
            offset += 1
            tagArray.append(data[offset])
            print("Three bytes tag length")
        } else {
            tagArray.append(data[offset])
            print("One byte tag length")
        }
        offset += 1
        return arrayToUInt16(tagArray);
    }
    
    private func getTagName(_ data:[UInt8], _ offset: inout Int) -> String{
        let tag:UInt8 = data[offset]
        self.tagTLV = tag
        self.tagTLVHex = tag.toAsciiHex()
        offset += 1
        var name = ""
        switch tag {
        case 0x01:
            name = "CardID"
        case 0x0C:
            name = "Card_Data"
        case 0x80:
            name = "Firmware"
        case 0x81:
            name = "Batch_ID"
        case 0x82:
            name = "Manufacture_Date_Time"
        case 0x83:
            name = "Issuer_Name"
        case 0x84:
            name = "Blockchain_Name"
        case 0x85:
            name = "Name_85"
        case 0x03:
            name = "Card_PublicKey"
        case 0x60:
            name = "Wallet_PublicKey"
        case 0x16:
            name = "Challenge"
        case 0x17:
            name = "Salt"
        case 0x40:
            name = "Wallet_PrivateKey"
        case 0x0F:
            name = "Health"
        case 0x62:
            name = "RemainingSignatures"
        case 0x61:
            name = "Wallet_Signature"
        case 0x63:
            name = "SignedHashes"
        default:
            name = ""
        }
        return name;
    }
    
    public static func checkPIN(_ data:[UInt8], _ offset: inout Int) -> Bool? {
        var tagArray:[UInt8] = [UInt8]()
        let checkOK:UInt16 = 0x9000
        let checkPIN:UInt16 = 0x6A86
        tagArray.append(data[offset])
        offset += 1
        tagArray.append(data[offset])
        offset += 1
        print(tagArray)
        if let twoFirstBytes:UInt16 = arrayToUInt16(tagArray){
            print(twoFirstBytes)
            if(twoFirstBytes == checkOK){
                print("Первые два байта равны 0x9000")
                return true
            }
            if(twoFirstBytes == checkPIN){
                return nil
            }
        }
        return nil
    }
}
