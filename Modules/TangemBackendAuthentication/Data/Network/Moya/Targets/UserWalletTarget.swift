//
//  UserWalletTarget.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public import struct Foundation.URL
public import struct Alamofire.HTTPMethod
public import Moya

public struct UserWalletTarget: Moya.TargetType {
    public let baseURL: URL
    public let path: String
    public let method: Alamofire.HTTPMethod
    public let task: Moya.Task
    public let validationType: Moya.ValidationType
    public let headers: [String: String]?

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

// MARK: - mobile/wallet/register and mobile/wallet/unregister

extension UserWalletTarget {
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
}
