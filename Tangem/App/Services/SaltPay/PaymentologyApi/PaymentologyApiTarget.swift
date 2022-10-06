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
            return "/card/set_kyc"
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
        case .registerKYC(let walletPublicKey):
            return .requestParameters(parameters: ["publicKey" : walletPublicKey.hexString], encoding: JSONEncoding())
        }
    }
    
    var headers: [String: String]? {
        [:]
    }
}

extension PaymentologyApiTarget {
    enum TargetType {
        case checkRegistration(request: CardVerifyAndGetInfoRequest)
        case requestAttestationChallenge(request: CardVerifyAndGetInfoRequest.Item)
        case registerWallet(request: ReqisterWalletRequest)
        case registerKYC(walletPublicKey: Data)
    }
}
