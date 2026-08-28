//
//  BackendAuthenticationTarget.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct Foundation.URL
import Alamofire
import Moya

struct BackendAuthenticationTarget: Moya.TargetType {
    let baseURL: URL
    let path: String
    let method: Alamofire.HTTPMethod
    let task: Moya.Task
    let validationType: Moya.ValidationType
    let headers: [String: String]?

    init(nonceForAuth requestBody: NonceDTO.Request, baseURL: URL) {
        self.init(
            baseURL: baseURL,
            path: "api/authentication/v1/mobile/nonce/auth",
            task: .requestJSONEncodable(requestBody)
        )
    }

    init(authenticate requestBody: AuthenticateDTO.Request, baseURL: URL) {
        self.init(
            baseURL: baseURL,
            path: "api/authentication/v1/mobile/authenticate",
            task: .requestJSONEncodable(requestBody)
        )
    }

    init(refreshToken requestBody: RefreshDTO.Request, baseURL: URL, dPoPProof: String, accessToken: String) {
        self.init(
            baseURL: baseURL,
            path: Self.refreshPath,
            task: .requestJSONEncodable(requestBody),
            additionalHeaders: DPoPHeadersFactory.make(accessToken: accessToken, dPoPProof: dPoPProof)
        )
    }

    static func refreshHTU(baseURL: URL) -> String {
        baseURL.appendingPathComponent(refreshPath).absoluteString
    }

    static let refreshHTM = Alamofire.HTTPMethod.post.rawValue

    private static let refreshPath = "api/authentication/v1/mobile/token/refresh"

    private init(baseURL: URL, path: String, task: Moya.Task, additionalHeaders: [String: String] = [:]) {
        self.baseURL = baseURL
        self.path = path
        self.task = task

        method = .post
        // Moya's default `.none` never calls Alamofire's `.validate()`, so a 401 would otherwise
        // complete as an ordinary "successful" response and our retrier would never see it.
        validationType = .successCodes
        headers = ["Content-Type": "application/json"].merging(additionalHeaders) { _, new in new }
    }
}
