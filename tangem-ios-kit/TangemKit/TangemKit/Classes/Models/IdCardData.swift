//
//  IdCardData.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Smart Cash AG. All rights reserved.
//

import Foundation
import TangemSdk


public struct IdCardData {
    public let fullname: String
    public let birthDay: String
    public let gender: String
    public let photo: Data
    public let issueDate: String
    public let expireDate: String
    public let trustedAddress: String
    
    init?(_ tlvData: Data) {
        guard let tlv = Tlv.deserialize(tlvData) else {
            return nil
        }
        
        do {
            let mapper = TlvMapper(tlv: tlv)
            fullname = try mapper.map(.fullname)
            birthDay = try mapper.map(.birthday)
            gender = try mapper.map(.gender)
            photo = try mapper.map(.photo)
            issueDate = try mapper.map(.issueDate)
            expireDate = try mapper.map(.expireDate)
            trustedAddress = try mapper.map(.trustedAddress)
        } catch {
            return nil
        }
    }
    
    func serialize() -> Data? {
        return try? TlvBuilder()
            .append(.fullname, value: fullname)
            .append(.birthday, value: birthDay)
            .append(.gender, value: gender)
            .append(.photo, value: photo)
            .append(.issueDate, value: issueDate)
            .append(.expireDate, value: expireDate)
            .append(.trustedAddress, value: trustedAddress)
            .serialize()
    }
}
