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

    init(registerWallet requestBody: RegisterWalletDTO.Request, baseURL: URL) {
        self.init(
            baseURL: baseURL,
            relativePath: "register",
            requestBody: requestBody
        )
    }

    init(unregisterWallet requestBody: UnregisterWalletDTO.Request, baseURL: URL) {
        self.init(
            baseURL: baseURL,
            relativePath: "unregister",
            requestBody: requestBody
        )
    }

    private init(baseURL: URL, relativePath: String, requestBody: some Encodable) {
        self.baseURL = baseURL
        path = Self.pathPrefix + relativePath
        task = .requestJSONEncodable(requestBody)

        method = .post
        // Moya's default `.none` never calls Alamofire's `.validate()`, so a 401 would otherwise
        // complete as an ordinary "successful" response and our retrier would never see it.
        validationType = .successCodes
        headers = ["Content-Type": "application/json"]
    }

    private static let pathPrefix = "api/authentication/v1/mobile/wallet/"
}
