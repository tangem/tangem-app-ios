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
    
    public init(fullname: String, birthDay: Date, gender: String, photo: Data, trustedAddress: String) {
        self.fullname = fullname
        self.gender = gender
        self.photo = photo
        self.trustedAddress = trustedAddress
        let issueDate = Date()
        let calendar = Calendar(identifier: .gregorian)
        let expireDate = calendar.date(byAdding: DateComponents.init(year: 10), to: issueDate)!
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        self.birthDay = dateFormatter.string(from: birthDay)
        self.issueDate = dateFormatter.string(from: issueDate)
        self.expireDate = dateFormatter.string(from: expireDate)
    }
    
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
    
    public func serialize() -> Data? {
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
