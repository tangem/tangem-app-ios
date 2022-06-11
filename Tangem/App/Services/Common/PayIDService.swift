//
//  PayIDService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemSdk
import BlockchainSdk
import Combine

enum PayIdStatus: Equatable {
    case notCreated
    case created(payId: String)
    case notSupported
}

enum PayIdError: Error {
    case anyError(message: String)
    case emptyResponse
    case unknown
}

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
    case XTZ
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
                                                   "key" : cardPublicKey.hexString], encoding: URLEncoding.default)
        case .createPayId(let cid, let cardPublicKey, let payId, let address, let network):
            return .requestParameters(parameters: ["cid" : cid,
                                                   "key" : cardPublicKey.hexString,
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

class PayIDService {
    let network: PayIdNetwork
    let payIdProvider = MoyaProvider<PayIdTarget>(/*plugins: [NetworkLoggerPlugin()]*/)
    
    internal init(network: PayIdNetwork) {
        self.network = network
    }
    
    static func make(from blockchain: Blockchain) -> PayIDService? {
        switch blockchain {
        case .binance(let testnet):
            if !testnet {
                return PayIDService(network: .BNB)
            }
        case .bitcoin(let testnet):
            if !testnet {
                return PayIDService(network: .BTC)
            }
        case .bitcoinCash(let testnet):
            if !testnet {
                return PayIDService(network: .BCH)
            }
        case .cardano(_):
            return PayIDService(network: .ADA)
        case .ducatus:
            return PayIDService(network: .DUC)
        case .ethereum(let testnet):
            if !testnet {
                return PayIDService(network: .ETH)
            }
        case .litecoin:
            return PayIDService(network: .LTC)
        case .rsk:
            return PayIDService(network: .RSK)
        case .stellar(let testnet):
            if !testnet {
                return PayIDService(network: .XLM)
            }
        case .xrp:
            return PayIDService(network: .XRPL)
        case .tezos:
            return PayIDService(network: .XTZ)
        default:
            break
        }
        return nil
    }
    
    
    func loadPayIDInfo (for card: Card) -> AnyPublisher<PayIdStatus, Error> {
        return loadPayId(cid: card.cardId, key: card.cardPublicKey)
    }
    
    
    private func loadPayId(cid: String, key: Data) -> AnyPublisher<PayIdStatus, Error> {
        return payIdProvider
            .requestPublisher(.getPayId(cid: cid, cardPublicKey: key))
            .filterSuccessfulStatusCodes()
            .map(GetPayIdResponse.self)
            .tryMap { payIdResponse -> PayIdStatus in
                if let payId = payIdResponse.payId {
                    return .created(payId: payId)
                }
                throw PayIdError.emptyResponse
            }
            .tryCatch{ error -> AnyPublisher<PayIdStatus, Error> in
                if let moyaError = error as? MoyaError,
                   case let .statusCode(response) = moyaError {
                    if response.statusCode == 404 {
                        return Just(PayIdStatus.notCreated)
                            .setFailureType(to: Error.self)
                            .eraseToAnyPublisher()
                    } else {
                        if let errorResponse = try? response.map(PayIdErrorResponse.self),
                           let msg = errorResponse.message {
                            throw PayIdError.anyError(message: msg)
                        }
                    }
                }
                
                throw error
            }
            .subscribe(on: DispatchQueue.global())
            .eraseToAnyPublisher()
    }
    
    func createPayId(cid: String, key: Data, payId: String, address: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        payIdProvider.request(.createPayId(cid: cid, cardPublicKey: key, payId: payId, address: address, network: self.network)) { moyaResult in
            DispatchQueue.main.async {
                switch moyaResult {
                case .success(let response):
                    do {
                        _ = try response.filterSuccessfulStatusCodes()
                        completion(.success(true))
                    } catch {
                        if response.statusCode == 409 {
                            completion(.failure("wallet_create_payid_error_already_created".localized))
                        } else if let errorResponse = try? response.map(PayIdErrorResponse.self), let msg = errorResponse.message {
                            completion(.failure(msg))
                        } else {
                            completion(.failure("wallet_create_payid_error_message".localized))
                        }
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    func validate(_ address: String) -> Bool {
        let lowercased = address.lowercased()
        let regex = NSRegularExpression("^[a-z0-9!#@%&*+/=?^_`{|}~-]+(?:\\.[a-z0-9!#@%&*+/=?^_`{|}~-]+)*\\$(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z-]*[a-z0-9])?|(?:[0-9]{1,3}\\.){3}[0-9]{1,3})$")
        
        guard regex.matches(lowercased) else {
            return false
        }
        
        let addressParts = lowercased.split(separator: "$")
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
    
    func resolve(_ payId: String, completion: @escaping (Result<PayIdAddressDetails, Error>) -> Void) {
        payIdProvider.request(.address(payId: payId, network: self.network)) {[weak self] moyaResult in
            guard let self = self else { return }
            switch moyaResult {
            case .success(let response):
                if let payIdResponse = try? response.map(PayIdResponse.self) {
                    if let resolvedAddressDetails = payIdResponse.addresses?.compactMap({ address -> PayIdAddressDetails? in
                        if address.paymentNetwork == self.network.rawValue && address.environment == "MAINNET" {
                            if address.addressDetails?.address != nil {
                                return address.addressDetails
                            } else {
                                return nil
                            }
                        }
                        return nil
                    }).first {
                        completion(.success(resolvedAddressDetails))
                    } else {
                        completion(.failure("payid_service_error_loading".localized))
                    }
                } else {
                    completion(.failure("payid_service_error_loading".localized))
                }
                
            case .failure(let error):
                Analytics.log(error: error)
                let err = "PayID request failed. \(error.localizedDescription)"
                print(err)
                completion(.failure("payid_service_error_loading".localized))
            }
        }
    }
}

