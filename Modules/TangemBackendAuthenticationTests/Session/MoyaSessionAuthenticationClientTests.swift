//
//  MoyaSessionAuthenticationClientTests.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import Alamofire
import Moya
import TangemFoundation
import TangemNetworkUtils
@testable import TangemBackendAuthentication

@Suite(.tags(.backendAuthentication))
struct MoyaSessionAuthenticationClientTests {
    @Test(arguments: StatusCodes.success)
    func requestCipheredNonceReturnsCipheredNonceOnSuccessStatusCode(successStatusCode: Int) async throws {
        let expectedCipheredNonce = "ciphered-value"
        let sut = try Self.makeSUT(
            statusCode: successStatusCode,
            responseBody: NonceResponseFixture.valid(cipheredNonce: expectedCipheredNonce)
        )

        let actualCipheredNonce = try await sut.requestCipheredNonce(devicePublicKey: .fake)

        #expect(actualCipheredNonce == expectedCipheredNonce)
    }

    @Test
    func requestCipheredNonceFailsOnUnexpectedResponseBody() async throws {
        let anySuccessStatusCode = 200
        let sut = try Self.makeSUT(statusCode: anySuccessStatusCode, responseBody: NonceResponseFixture.invalid)

        let error = try await #require(throws: SessionAuthenticationClientError.self) {
            _ = try await sut.requestCipheredNonce(devicePublicKey: .fake)
        }

        guard case .requestNonceFailed = error else {
            Issue.record("Expected .requestNonceFailed, got \(error)")
            return
        }
    }

    @Test
    func requestCipheredNonceThrowsRequestNonceTimeoutOnTimeoutNetworkError() async throws {
        let sut = try Self.makeSUT(networkError: AFError.timeoutFake)

        let error = try await #require(throws: SessionAuthenticationClientError.self) {
            _ = try await sut.requestCipheredNonce(devicePublicKey: .fake)
        }

        guard case .requestNonceTimeout = error else {
            Issue.record("Expected .requestNonceTimeout, got \(error)")
            return
        }
    }

    @Test
    func requestCipheredNonceThrowsRequestNonceFailedOnNonTimeoutNetworkError() async throws {
        let sut = try Self.makeSUT(networkError: AFError.notConnectedToInternetFake)

        let error = try await #require(throws: SessionAuthenticationClientError.self) {
            _ = try await sut.requestCipheredNonce(devicePublicKey: .fake)
        }

        guard case .requestNonceFailed = error else {
            Issue.record("Expected .requestNonceFailed, got \(error)")
            return
        }
    }

    @Test(arguments: StatusCodes.success)
    func authenticateReturnsSessionTokensOnSuccess(successStatusCode: Int) async throws {
        let expectedAccessToken = "access-jwt"
        let expectedRefreshToken = "refresh-jwt"
        let sut = try Self.makeSUT(
            statusCode: successStatusCode,
            responseBody: TokensResponseFixture.valid(accessToken: expectedAccessToken, refreshToken: expectedRefreshToken)
        )

        let sessionTokens = try await sut.authenticate(
            devicePublicKey: .fake,
            decryptedNonce: "decrypted-nonce",
            metadata: .fake,
            signature: .fake,
            attestationToken: nil
        )

        #expect(sessionTokens.accessToken.jwt == expectedAccessToken)
        #expect(sessionTokens.refreshToken?.jwt == expectedRefreshToken)
    }

    @Test
    func authenticateThrowsAuthenticateFailedOnUnexpectedResponseBody() async throws {
        let anySuccessStatusCode = 200
        let sut = try Self.makeSUT(
            statusCode: anySuccessStatusCode,
            responseBody: TokensResponseFixture.invalidWithUnixTimestampDateFormat
        )

        let error = try await #require(throws: SessionAuthenticationClientError.self) {
            _ = try await sut.authenticate(
                devicePublicKey: .fake,
                decryptedNonce: "decrypted-nonce",
                metadata: .fake,
                signature: .fake,
                attestationToken: nil
            )
        }

        guard case .authenticateFailed = error else {
            Issue.record("Expected .authenticateFailed, got \(error)")
            return
        }
    }

    @Test(arguments: StatusCodes.authenticationRejection)
    func authenticateThrowsAuthenticationRejectedForRejectionStatusCode(authenticationRejectionStatusCode: Int) async throws {
        let sut = try Self.makeSUT(statusCode: authenticationRejectionStatusCode)

        let error = try await #require(throws: SessionAuthenticationClientError.self) {
            _ = try await sut.authenticate(
                devicePublicKey: .fake,
                decryptedNonce: "decrypted-nonce",
                metadata: .fake,
                signature: .fake,
                attestationToken: nil
            )
        }

        guard case .authenticationRejected = error else {
            Issue.record("Expected .authenticationRejected, got \(error)")
            return
        }
    }

    @Test
    func authenticateThrowsDeviceRegistrationMissingForDeviceNotFoundError() async throws {
        let notFoundStatusCode = 404
        let sut = try Self.makeSUT(statusCode: notFoundStatusCode, responseBody: TokensResponseFixture.deviceNotFoundErrorResponse)

        let error = try await #require(throws: SessionAuthenticationClientError.self) {
            _ = try await sut.authenticate(
                devicePublicKey: .fake,
                decryptedNonce: "decrypted-nonce",
                metadata: .fake,
                signature: .fake,
                attestationToken: nil
            )
        }

        guard case .deviceRegistrationMissing = error else {
            Issue.record("Expected .deviceRegistrationMissing, got \(error)")
            return
        }
    }

    @Test(arguments: [
        TokensResponseFixture.nonceNotFoundErrorResponse,
        TokensResponseFixture.tokenNotFoundErrorResponse,
        TokensResponseFixture.emptyErrorResponse,
    ])
    func authenticateThrowsAuthenticateFailedForNotFoundErrorsOtherThanDeviceNotFound(responseBody: String) async throws {
        let notFoundStatusCode = 404
        let sut = try Self.makeSUT(statusCode: notFoundStatusCode, responseBody: responseBody)

        let error = try await #require(throws: SessionAuthenticationClientError.self) {
            _ = try await sut.authenticate(
                devicePublicKey: .fake,
                decryptedNonce: "decrypted-nonce",
                metadata: .fake,
                signature: .fake,
                attestationToken: nil
            )
        }

        guard case .authenticateFailed = error else {
            Issue.record("Expected .authenticateFailed, got \(error)")
            return
        }
    }

    @Test(arguments: StatusCodes.error)
    func authenticateThrowsAuthenticateFailedOnErrorStatusCode(errorStatusCode: Int) async throws {
        let sut = try Self.makeSUT(statusCode: errorStatusCode)

        let error = try await #require(throws: SessionAuthenticationClientError.self) {
            _ = try await sut.authenticate(
                devicePublicKey: .fake,
                decryptedNonce: "decrypted-nonce",
                metadata: .fake,
                signature: .fake,
                attestationToken: nil
            )
        }

        guard case .authenticateFailed = error else {
            Issue.record("Expected .authenticateFailed, got \(error)")
            return
        }
    }

    @Test(arguments: StatusCodes.success)
    func refreshReturnsSessionTokensOnSuccessStatusCode(successStatusCode: Int) async throws {
        let expectedAccessToken = "access-jwt"
        let expectedRefreshToken = "refresh-jwt"
        let sut = try Self.makeSUT(
            statusCode: successStatusCode,
            responseBody: TokensResponseFixture.valid(accessToken: expectedAccessToken, refreshToken: expectedRefreshToken),
            headersSpy: { actualHeaders in
                #expect(actualHeaders?["Authorization"] == "DPoP access-jwt")
                #expect(actualHeaders?["DPoP"] != nil)
            }
        )

        let sessionTokens = try await sut.refresh(refreshToken: "refresh-jwt", accessToken: "access-jwt")

        #expect(sessionTokens.accessToken.jwt == expectedAccessToken)
        #expect(sessionTokens.refreshToken?.jwt == expectedRefreshToken)
    }

    @Test
    func refreshThrowsRefreshFailedOnUnexpectedResponseBody() async throws {
        let anySuccessStatusCode = 200
        let sut = try Self.makeSUT(
            statusCode: anySuccessStatusCode,
            responseBody: TokensResponseFixture.invalidWithUnixTimestampDateFormat
        )

        let error = try await #require(throws: SessionAuthenticationClientError.self) {
            _ = try await sut.refresh(refreshToken: "refresh-jwt", accessToken: "access-jwt")
        }

        guard case .refreshFailed = error else {
            Issue.record("Expected .refreshFailed, got \(error)")
            return
        }
    }

    @Test(arguments: StatusCodes.error)
    func refreshThrowsRefreshFailedOnErrorStatusCode(errorStatusCode: Int) async throws {
        let sut = try Self.makeSUT(statusCode: errorStatusCode)

        let error = try await #require(throws: SessionAuthenticationClientError.self) {
            _ = try await sut.refresh(refreshToken: "refresh-jwt", accessToken: "access-jwt")
        }

        guard case .refreshFailed = error else {
            Issue.record("Expected .refreshFailed, got \(error)")
            return
        }
    }
}

// MARK: - Factory methods

extension MoyaSessionAuthenticationClientTests {
    private static func makeSUT(
        statusCode: Int,
        responseBody: String = "",
        headersSpy: (([String: String]?) -> Void)? = nil,
        sourceLocation: SourceLocation = #_sourceLocation
    ) throws -> MoyaSessionAuthenticationClient {
        try makeSUT(
            endpointClosure: { target in
                headersSpy?(target.headers)
                return Endpoint.stub(target: target, statusCode: statusCode, responseBody: responseBody)
            },
            sourceLocation: sourceLocation
        )
    }

    private static func makeSUT(
        networkError: some Error,
        sourceLocation: SourceLocation = #_sourceLocation
    ) throws -> MoyaSessionAuthenticationClient {
        try makeSUT(
            endpointClosure: { target in
                Endpoint.stub(target: target, sampleResponse: .networkError(networkError as NSError))
            },
            sourceLocation: sourceLocation
        )
    }

    private static func makeSUT(
        endpointClosure: @escaping MoyaProvider<BackendAuthenticationTarget>.EndpointClosure,
        sourceLocation: SourceLocation = #_sourceLocation
    ) throws -> MoyaSessionAuthenticationClient {
        let provider = MoyaProvider<BackendAuthenticationTarget>(
            endpointClosure: endpointClosure,
            stubClosure: MoyaProvider.immediatelyStub
        )

        let anyBaseURL = try #require(URL(string: "https://example.com"), sourceLocation: sourceLocation)

        let dPoPProofGenerator = DPoPProofGenerator(
            deviceKeyManager: DeviceKeyManager(privateKeyRepository: .successStub)
        )

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .customISO8601

        return MoyaSessionAuthenticationClient(
            dPoPProofGenerator: dPoPProofGenerator,
            provider: provider,
            baseURL: anyBaseURL,
            decoder: decoder
        )
    }
}

// MARK: - Fixtures

extension MoyaSessionAuthenticationClientTests {
    private enum StatusCodes {
        static let success = [200, 201, 202, 203, 204, 205, 206, 207, 208, 226]
        static let error = [400, 402, 500, 501, 512]
        static let authenticationRejection = [401, 403]
    }
}

private extension TokensResponseFixture {
    static let deviceNotFoundErrorResponse = TangemProblemDetailError.deviceNotFound.jsonString
    static let nonceNotFoundErrorResponse = #"{"detail":"Nonce not found"}"#
    static let tokenNotFoundErrorResponse = #"{"detail":"Token not found"}"#
    static let emptyErrorResponse = ""
}
