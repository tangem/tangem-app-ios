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

enum PayIdNetwork: String {
    case XRPL
}

enum PayIdTarget: TargetType {
    case address(payId: String)
    case getPayId(cid: String, cardPublicKey:Data)
    case createPayId(cid: String, cardPublicKey:Data, payId: String, address: String, network: PayIdNetwork)
    
    var baseURL: URL {
        switch self {
        case .address(let payId):
            let addressParts = payId.split(separator: "$")
            let domain = addressParts[1]
            let baseUrl = "https://\(domain)/"
            return URL(string: baseUrl)!
        default:
            return URL(string: "https://payid.tangem.com")!
        }
    }
    
    var path: String {
        switch self {
        case .address(let payId):
            let addressParts = payId.split(separator: "$")
            let user = addressParts[0]
            return String(user)
        default:
            return ""
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .address:
            return .get
        case .getPayId:
            return .get
        case .createPayId:
            return .post
        }
    }
    
    var sampleData: Data {
        return Data()
    }
    
    var task: Task {
        switch self {
        case .address:
            return .requestPlain
        case .getPayId(let cid, let cardPublicKey):
            return .requestParameters(parameters: ["cid" : cid,
                                                   "key" : cardPublicKey.asHexString()], encoding: URLEncoding.default)
        case .createPayId(let cid, let cardPublicKey, let payId, let address, let network):
            return .requestParameters(parameters: ["cid" : cid,
                                                   "key" : cardPublicKey.asHexString(),
                                                   "payid" : payId,
                                                   "address" : address,
                                                   "network" : network.rawValue
            ], encoding: URLEncoding.default)
        }
    }
    
    public var headers: [String: String]? {
        switch self {
        case .address:
            return ["Accept" : "application/xrpl-mainnet+json",
                    "PayID-Version" : "1.0"]
        default:
            return nil
        }
        
    }
    
}

struct GetPayIdResponse: Codable {
    let payId: String?
}

struct CreatePayIdResponse: Codable {
    let success: Bool?
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


protocol PayIdProvider {
    func loadPayId(cid: String, key: Data, completion: @escaping (Result<String?, Error>) -> Void)
    func createPayId(cid: String, key: Data, payId: String, address: String, completion: @escaping (Result<Bool, Error>) -> Void)
}
