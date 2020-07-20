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

struct PayIdErrorResponse: Codable {
    let code: Int?
    let message: String?
}

struct PayIdAddress: Codable {
    let paymentNetwork: String
    let environment: String
    let addressDetails: PayIdAddressDetails?
}

struct PayIdAddressDetails: Codable {
    let address: String?
    let tag: String?
}

enum PayIdNetwork: String {
    case XRPL
    case BTC
    case ETH
    case LTC
    case XLM
    case BCH
    case BNB
    case RSK
    case ADA
    case DUC
}

enum PayIdTarget: TargetType {
    case address(payId: String, network: PayIdNetwork)
    case getPayId(cid: String, cardPublicKey:Data)
    case createPayId(cid: String, cardPublicKey:Data, payId: String, address: String, network: PayIdNetwork)
    
    var baseURL: URL {
        switch self {
        case .address(let payId, _):
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
        case .address(let payId, _):
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
        case .address(_, let network):
            return ["Accept" : "application/\(network.rawValue.lowercased())-mainnet+json",
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
    var payIdManager: PayIdManager? { get }
}


class PayIdManager {
    
    internal init(network: PayIdNetwork) {
        self.network = network
    }
    
    let network: PayIdNetwork
    
    public private(set) var payId: String?
    public private(set) var resolvedTag: String?
    
    let payIdProvider = MoyaProvider<PayIdTarget>(plugins: [NetworkLoggerPlugin()])
    
    func loadPayId(cid: String, key: Data, completion: @escaping (Result<String?, Error>) -> Void) {
        payIdProvider.request(.getPayId(cid: cid, cardPublicKey: key)) {[weak self] moyaResult in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch moyaResult {
                case .success(let response):
                    do {
                        _ = try response.filterSuccessfulStatusCodes()
                        if let getResponse = try? response.map(GetPayIdResponse.self) {
                            if let payId = getResponse.payId {
                                self.payId = payId
                                completion(.success(payId))
                            } else {
                                self.payId = nil
                                completion(.failure("Empty PayID response"))
                            }
                        } else {
                            self.payId = nil
                            completion(.failure("Unknown PayID response"))
                        }
                    } catch {
                        if response.statusCode == 404 {
                            self.payId = nil
                            completion(.success(nil))
                            return
                        } else {
                            self.payId = nil
                            if let errorResponse = try? response.map(PayIdErrorResponse.self), let msg = errorResponse.message {
                                completion(.failure(msg))
                            } else {
                                completion(.failure("Request failed. Try again later"))
                            }
                        }
                    }
                case .failure(let error):
                    self.payId = nil
                    completion(.failure(error))
                }
            }
        }
    }
    
    func createPayId(cid: String, key: Data, payId: String, address: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        payIdProvider.request(.createPayId(cid: cid, cardPublicKey: key, payId: payId, address: address, network: self.network)) {[weak self] moyaResult in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch moyaResult {
                case .success(let response):
                    do {
                        _ = try response.filterSuccessfulStatusCodes()
                        self.payId = payId
                        completion(.success(true))
                    } catch {
                        if let errorResponse = try? response.map(PayIdErrorResponse.self), let msg = errorResponse.message {
                            completion(.failure(msg))
                        } else {
                            completion(.failure("Request failed. Try again later"))
                        }
                        
                        self.payId = nil
                    }
                case .failure(let error):
                    self.payId = nil
                    completion(.failure(error))
                }
            }
        }
    }
    
    func validate(_ address: String) -> Bool {
        let addressParts = address.split(separator: "$")
        if addressParts.count != 2 {
            return false
        }
        let addressURL = "https://" + addressParts[1] + "/" + addressParts[0]
        if let _ = URL(string: addressURL) {
            return true
        } else {
            return false
        }
    }
    
    func resolve(_ payId: String, completion: @escaping (Result<String, Error>) -> Void) {
        self.resolvedTag = nil
        payIdProvider.request(.address(payId: payId, network: self.network)) {[weak self] moyaResult in
            guard let self = self else { return }
            switch moyaResult {
            case .success(let response):
                if let payIdResponse = try? response.map(PayIdResponse.self) {
                    if let resolvedAddressDetails = payIdResponse.addresses?.compactMap({ address -> (address: String, tag: String?)? in
                        if address.paymentNetwork == self.network.rawValue && address.environment == "MAINNET" {
                            if let resolvedAddress = address.addressDetails?.address {
                                return (resolvedAddress, address.addressDetails?.tag)
                            } else {
                                return nil
                            }
                        }
                        return nil
                        }).first {
                        
                        self.resolvedTag = resolvedAddressDetails.tag
                        completion(.success(resolvedAddressDetails.address))
                    } else {
                        completion(.failure("Unknown address format in PayID response"))
                    }
                } else {
                    completion(.failure("Unknown response format on PayID request"))
                }
                
            case .failure(let error):
                let err = "PayID request failed. \(error.localizedDescription)"
                completion(.failure(err))
            }
        }
    }
}
