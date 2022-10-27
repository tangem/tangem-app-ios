//
//  PaymentologyApiTarget.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Moya
import TangemSdk

struct PaymentologyApiTarget: TargetType {
    let type: TargetType

    var baseURL: URL { URL(string: "https://paymentologygate.oa.r.appspot.com")! }

    var path: String {
        switch type {
        case .checkRegistration:
            return "/card/verify"
        case .requestAttestationChallenge:
            return "/card/get_challenge"
        case .registerWallet:
            return "/card/set_pin"
        case .registerKYC:
            return "/card/kyc"
        }
    }

    var method: Moya.Method {
        .post
    }

    var task: Task {
        switch type {
        case .checkRegistration(let request):
            return .requestJSONEncodable(request)
        case .requestAttestationChallenge(let request):
            return .requestJSONEncodable(request)
        case .registerWallet(let request):
            return .requestCustomJSONEncodable(request, encoder: JSONEncoder.saltPayEncoder)
        case .registerKYC(let request):
            return .requestCustomJSONEncodable(request, encoder: JSONEncoder.saltPayEncoder)
        }
    }

    var headers: [String: String]? {
        [:]
    }

    var sampleData: Data {
        switch type {
        case .checkRegistration:
            let url = Bundle.main.url(forResource: "registration_mock", withExtension: "json")!
            let data = try! Data(contentsOf: url)
            return data
        case .requestAttestationChallenge:
            let response = AttestationResponse(challenge: try! CryptoUtils.generateRandomBytes(count: 16),
                                               error: nil,
                                               errorCode: nil,
                                               success: true)
            let data = try! JSONEncoder.saltPayEncoder.encode(response)
            return data
        case .registerWallet:
            let response = RegisterWalletResponse(error: nil, errorCode: nil, success: true)
            let data = try! JSONEncoder.saltPayEncoder.encode(response)
            return data
        case .registerKYC:
            let response = RegisterWalletResponse(error: nil, errorCode: nil, success: true)
            let data = try! JSONEncoder.saltPayEncoder.encode(response)
            return data
        }
    }
}

extension PaymentologyApiTarget {
    enum TargetType {
        case checkRegistration(request: CardVerifyAndGetInfoRequest)
        case requestAttestationChallenge(request: CardVerifyAndGetInfoRequest.Item)
        case registerWallet(request: ReqisterWalletRequest)
        case registerKYC(request: RegisterKYCRequest)
    }
}

extension JSONDecoder {
    static var saltPayDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dataDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let hex = try container.decode(String.self)
            return Data(hexString: hex)
        }

        return decoder
    }
}

extension JSONEncoder {
    static var saltPayEncoder: JSONEncoder  {
        let encoder = JSONEncoder()
        encoder.dataEncodingStrategy = .custom { data, encoder in
            var container = encoder.singleValueContainer()
            return try container.encode(data.hexString)
        }

        return encoder
    }
}
