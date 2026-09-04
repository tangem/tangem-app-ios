//
//  BackendAuthenticationTarget.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public import struct Foundation.URL
public import struct Alamofire.HTTPMethod
public import Moya

public struct BackendAuthenticationTarget: Moya.TargetType {
    public let baseURL: URL
    public let path: String
    public let method: Alamofire.HTTPMethod
    public let task: Moya.Task
    public let validationType: Moya.ValidationType
    public let headers: [String: String]?

    private init(baseURL: URL, relativePath: String, requestBody: some Encodable, additionalHeaders: [String: String] = [:]) {
        self.baseURL = baseURL
        path = Self.pathPrefix + relativePath
        task = .requestJSONEncodable(requestBody)

        method = Self.httpMethod
        // Moya's default `.none` never calls Alamofire's `.validate()`, so a 401 would otherwise
        // complete as an ordinary "successful" response and our retrier would never see it.
        validationType = .successCodes
        headers = ["Content-Type": "application/json"].merging(additionalHeaders) { _, new in new }
    }

    fileprivate static let pathPrefix = "api/authentication/v1/mobile/"
    fileprivate static let httpMethod = Alamofire.HTTPMethod.post
}

// MARK: - mobile/nonce

extension BackendAuthenticationTarget {
    init(authenticationNonce requestBody: NonceDTO.Request, baseURL: URL) {
        self.init(
            baseURL: baseURL,
            relativePath: "nonce/auth",
            requestBody: requestBody
        )
    }

    init(deviceRegistrationNonce requestBody: NonceDTO.Request, baseURL: URL) {
        self.init(
            baseURL: baseURL,
            relativePath: "nonce/device",
            requestBody: requestBody
        )
    }

    init(walletRegistrationNonce requestBody: NonceDTO.Request, baseURL: URL) {
        self.init(
            baseURL: baseURL,
            relativePath: "nonce/wallet",
            requestBody: requestBody
        )
    }
}

// MARK: - mobile/authenticate

extension BackendAuthenticationTarget {
    init(authenticate requestBody: AuthenticateDTO.Request, baseURL: URL) {
        self.init(
            baseURL: baseURL,
            relativePath: "authenticate",
            requestBody: requestBody
        )
    }
}

// MARK: - mobile/register

extension BackendAuthenticationTarget {
    init(registerDevice requestBody: RegisterDeviceDTO.Request, baseURL: URL) {
        self.init(
            baseURL: baseURL,
            relativePath: "register",
            requestBody: requestBody
        )
    }
}

// MARK: - mobile/token/refresh

extension BackendAuthenticationTarget {
    init(authenticationRefresh requestBody: RefreshDTO.Request, baseURL: URL, dPoPProof: String, accessToken: String) {
        self.init(
            baseURL: baseURL,
            relativePath: Refresh.relativePath,
            requestBody: requestBody,
            additionalHeaders: DPoPHeadersFactory.make(accessToken: accessToken, dPoPProof: dPoPProof)
        )
    }

    enum Refresh {
        static func htu(_ baseURL: URL) -> String {
            baseURL.appendingPathComponent(BackendAuthenticationTarget.pathPrefix + relativePath).absoluteString
        }

        static let htm = BackendAuthenticationTarget.httpMethod.rawValue
        fileprivate static let relativePath = "token/refresh"
    }
}
