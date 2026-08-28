//
//  UserWalletTarget.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct Foundation.URL
import Alamofire
import Moya

struct UserWalletTarget: Moya.TargetType {
    let baseURL: URL
    let path: String
    let method: Alamofire.HTTPMethod
    let task: Moya.Task
    let validationType: Moya.ValidationType
    let headers: [String: String]?

    init(register requestBody: WalletRegistrationDTO.Request, baseURL: URL) {
        self.init(
            baseURL: baseURL,
            path: "api/authentication/v1/mobile/wallet/register",
            task: .requestJSONEncodable(requestBody)
        )
    }

    init(unregister requestBody: WalletUnregistrationDTO.Request, baseURL: URL) {
        self.init(
            baseURL: baseURL,
            path: "api/authentication/v1/mobile/wallet/unregister",
            task: .requestJSONEncodable(requestBody)
        )
    }

    private init(baseURL: URL, path: String, task: Moya.Task) {
        self.baseURL = baseURL
        self.path = path
        self.task = task

        method = .post
        // Moya's default `.none` never calls Alamofire's `.validate()`, so a 401 would otherwise
        // complete as an ordinary "successful" response and our retrier would never see it.
        validationType = .successCodes
        headers = ["Content-Type": "application/json"]
    }
}
