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
            return .requestCustomJSONEncodable(request, encoder: JSONEncoder.tangemSdkEncoder)
        case .registerKYC(let request):
            return .requestCustomJSONEncodable(request, encoder: JSONEncoder.tangemSdkEncoder)
        }
    }

    var headers: [String: String]? {
        [:]
    }

    var sampleData: Data {
        switch type {
        case .checkRegistration(let request):
            let item = RegistrationResponse.Item(cardId: request.requests[0].cardId,
                                                 error: nil,
                                                 passed: true,
                                                 active: false,
                                                 pinSet: true,
                                                 blockchainInit: nil,
                                                 kycPassed: nil,
                                                 kycProvider: "SomeProvider",
                                                 kycDate: nil,
                                                 disabledByAdmin: nil)

            let response = RegistrationResponse(results: [item],
                                                error: nil,
                                                errorCode: nil,
                                                success: true)

            let data = try! JSONEncoder.tangemSdkEncoder.encode(response)
            return data
        case .requestAttestationChallenge:
            let response = AttestationResponse(challenge: try! CryptoUtils.generateRandomBytes(count: 16),
                                               error: nil,
                                               errorCode: nil,
                                               success: true)
            let data = try! JSONEncoder.tangemSdkEncoder.encode(response)
            return data
        case .registerWallet:
            let response = RegisterWalletResponse(error: nil, errorCode: nil, success: true)
            let data = try! JSONEncoder.tangemSdkEncoder.encode(response)
            return data
        case .registerKYC:
            let response = RegisterWalletResponse(error: nil, errorCode: nil, success: true)
            let data = try! JSONEncoder.tangemSdkEncoder.encode(response)
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
