//
//  ProductActivationAPITarget.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemNetworkUtils
import Moya
import TangemPay

struct ProductActivationAPITarget: TargetType {
    let target: Target
    let apiType: TangemPayAPIType

    var baseURL: URL {
        apiType.bffBaseURL.appendingPathComponent("activation")
    }

    var path: String {
        switch target {
        case .activationStatus:
            return "status"
        case .getAcceptanceMessage:
            return "acceptance/message"
        case .approveDeployByVisaCard, .approveDeployByCustomerWallet:
            return "data"
        case .setupPIN:
            return "pin"
        }
    }

    var method: Moya.Method {
        .post
    }

    var task: Task {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.keyEncodingStrategy = .convertToSnakeCase
        switch target {
        case .activationStatus(let request):
            return .requestCustomJSONEncodable(request, encoder: jsonEncoder)
        case .getAcceptanceMessage(let request):
            return .requestCustomJSONEncodable(request, encoder: jsonEncoder)
        case .approveDeployByVisaCard(let request):
            return .requestCustomJSONEncodable(request, encoder: jsonEncoder)
        case .approveDeployByCustomerWallet(let request):
            return .requestCustomJSONEncodable(request, encoder: jsonEncoder)
        case .setupPIN(let request):
            return .requestCustomJSONEncodable(request, encoder: jsonEncoder)
        }
    }

    var headers: [String: String]? {
        ["Content-Type": "application/json"]
    }
}

extension ProductActivationAPITarget {
    enum Target {
        /// Load remote activation status to identify current activation state and decide where to navigate user while onboarding
        case activationStatus(request: ActivationStatusRequest)
        /// There are two types of acceptance messages:
        /// 1. Acceptance message that must be signed by Visa card
        /// 2. Acceptance message that must be signed by other wallet - it can be Tangem card or external wallet that was used to buy Visa card
        /// Each of this messages must be signed during onboarding to initiate payment account deployment proccess
        case getAcceptanceMessage(request: GetAcceptanceMessageRequest)
        /// Send to backend signed acceptance message by visa card
        case approveDeployByVisaCard(request: VisaCardDeployAcceptanceRequest)
        /// Send to backend signed acceptance message by Tangem card. If Visa card was ordered by external wallet - it will approve payment
        /// account deployment through dApp
        case approveDeployByCustomerWallet(request: CustomerWalletDeployAcceptanceRequest)
        /// Send selected PIN to external service for validation and setup. This is the final step of Visa card activation process
        case setupPIN(request: SetupPINRequest)
    }
}

extension ProductActivationAPITarget: TargetTypeLogConvertible {
    var requestDescription: String {
        path
    }

    var shouldLogResponseBody: Bool {
        return false
    }
}
