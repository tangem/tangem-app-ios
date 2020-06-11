//
//  PayID.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Smart Cash AG. All rights reserved.
//

import Foundation
import Moya
import TangemSdk

struct PayIdResponse: Codable {
    let addresses: [PayIdAddress]?
}

struct PayIdAddress: Codable {
    let paymentNetwork: String
    let environment: String
    let addressDetails: PayIdAddressDetails?
}

struct PayIdAddressDetails: Codable {
    let address: String?
}

enum PayIdTarget: TargetType {
    case address(payId: String)
    
    var baseURL: URL {
        switch self {
        case .address(let payId):
            let addressParts = payId.split(separator: "$")
            let domain = addressParts[1]
            let baseUrl = "https://\(domain)/"
            return URL(string: baseUrl)!
        }
    }
    
    var path: String {
        switch self {
        case .address(let payId):
            let addressParts = payId.split(separator: "$")
            let user = addressParts[0]
            return String(user)
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .address:
            return .get
        }
    }
    
    var sampleData: Data {
        return Data()
    }
    
    var task: Task {
        switch self {
        case .address:
            return .requestPlain
        }
    }
    
    public var headers: [String: String]? {
        switch self {
        case .address:
            return ["Accept" : "application/xrpl-mainnet+json",
                    "PayID-Version" : "1.0"]
        }
    }
    
}


/*class XrpXAddressService {
    private let xrpMainnetPrefix = Data([UInt8(0x05), UInt8(0x44)])
    private let zeroTagBytes = Data(repeating: UInt8(0), count: 4)

    
    func validate(address: String) -> Bool {
        return decode(address: address) != nil
    }
    
    func decode(address: String) -> XrpXAddressDecoded? {
        guard var addressData = Data(base58Decoding: address) else {
            return nil
        }
        
        addressData[0] = 0
        let accountID = [UInt8](addressData.prefix(addressData.count-4))
        let checksum = [UInt8](addressData.suffix(4))
        let _checksum = [UInt8](Data(accountID).sha256().sha256().prefix(through: 3))
        if checksum != _checksum {
            return nil
        }
        
        
        if addressData.count != 31 {
            return nil
        }
        
        let prefix = addressData[0...1]
        if prefix != xrpMainnetPrefix {
            return nil
        }
        
        let accountData = addressData[2...21]
        guard let classicAddress = try? XRPWallet.encodeAccountId(bytes:accountData) else {
            return nil
        }
        
        let flag = accountData[22]
        
        let tagData = addressData[23...26]
        let reservedTagData = addressData[27...30]
        if reservedTagData != zeroTagBytes {
            return nil
        }
        
        var tag: Int? = nil
        switch flag {
        case UInt8(0):
            if tagData != zeroTagBytes {
                return nil
            }
        case UInt8(1):
            tag = Data(tagData.reversed()).toInt()
        default:
            return nil
        }

        return XrpXAddressDecoded(address: classicAddress, destinationTag: tag)
    }
}

struct XrpXAddressDecoded {
    let address: String
    let destinationTag: Int?
}
*/
