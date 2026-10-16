//
//  MoyaUserWalletRegistrationClientTests.swift
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
@testable import TangemBackendAuthentication

@Suite(.tags(.backendAuthentication))
struct MoyaUserWalletRegistrationClientTests {
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
    func requestCipheredNonceThrowsRequestNonceFailedOnUnexpectedResponseBody() async throws {
        let anySuccessStatusCode = 200
        let sut = try Self.makeSUT(statusCode: anySuccessStatusCode, responseBody: NonceResponseFixture.invalid)

        let error = try await #require(throws: UserWalletRegistrationClientError.self) {
            _ = try await sut.requestCipheredNonce(devicePublicKey: .fake)
        }

        guard case .requestNonceFailed = error else {
            Issue.record("Expected .requestNonceFailed, got \(error)")
            return
        }
    }

    @Test(arguments: StatusCodes.error)
    func requestCipheredNonceThrowsRequestNonceFailedOnErrorStatusCode(errorStatusCode: Int) async throws {
        let sut = try Self.makeSUT(statusCode: errorStatusCode)

        let error = try await #require(throws: UserWalletRegistrationClientError.self) {
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

        let error = try await #require(throws: UserWalletRegistrationClientError.self) {
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

        let error = try await #require(throws: UserWalletRegistrationClientError.self) {
            _ = try await sut.requestCipheredNonce(devicePublicKey: .fake)
        }

        guard case .requestNonceFailed = error else {
            Issue.record("Expected .requestNonceFailed, got \(error)")
            return
        }
    }

    @Test(arguments: StatusCodes.success)
    func registerReturnsSessionTokensOnSuccessStatusCode(successStatusCode: Int) async throws {
        let expectedAccessToken = "access-jwt"
        let expectedRefreshToken = "refresh-jwt"
        let sut = try Self.makeSUT(
            statusCode: successStatusCode,
            responseBody: TokensResponseFixture.valid(accessToken: expectedAccessToken, refreshToken: expectedRefreshToken)
        )

        let sessionTokens = try await sut.register(request: .fake)

        #expect(sessionTokens.accessToken.jwt == expectedAccessToken)
        #expect(sessionTokens.refreshToken?.jwt == expectedRefreshToken)
    }

    @Test
    func registerThrowsRegisterFailedOnUnexpectedResponseBody() async throws {
        let anySuccessStatusCode = 200
        let sut = try Self.makeSUT(
            statusCode: anySuccessStatusCode,
            responseBody: TokensResponseFixture.invalidWithUnixTimestampDateFormat
        )

        let error = try await #require(throws: UserWalletRegistrationClientError.self) {
            _ = try await sut.register(request: .fake)
        }

        guard case .registerFailed = error else {
            Issue.record("Expected .registerFailed, got \(error)")
            return
        }
    }

    @Test
    func registerThrowsAlreadyRegisteredFor400WithMatchingProblemDetail() async throws {
        let sut = try Self.makeSUT(statusCode: 400, responseBody: Self.problemDetailBody(.walletAlreadyRegistered))

        let error = try await #require(throws: UserWalletRegistrationClientError.self) {
            _ = try await sut.register(request: .fake)
        }

        guard case .alreadyRegistered = error else {
            Issue.record("Expected .alreadyRegistered, got \(error)")
            return
        }
    }

    @Test
    func registerThrowsRegisterFailedFor400WithNonMatchingProblemDetail() async throws {
        let sut = try Self.makeSUT(statusCode: 400, responseBody: Self.problemDetailBody(.walletNotRegistered))

        let error = try await #require(throws: UserWalletRegistrationClientError.self) {
            _ = try await sut.register(request: .fake)
        }

        guard case .registerFailed = error else {
            Issue.record("Expected .registerFailed, got \(error)")
            return
        }
    }

    @Test(arguments: StatusCodes.error)
    func registerThrowsRegisterFailedOnErrorStatusCode(errorStatusCode: Int) async throws {
        let sut = try Self.makeSUT(statusCode: errorStatusCode)

        let error = try await #require(throws: UserWalletRegistrationClientError.self) {
            _ = try await sut.register(request: .fake)
        }

        guard case .registerFailed = error else {
            Issue.record("Expected .registerFailed, got \(error)")
            return
        }
    }

    @Test(arguments: StatusCodes.success)
    func unregisterReturnsSessionTokensOnSuccessStatusCode(successStatusCode: Int) async throws {
        let expectedAccessToken = "access-jwt"
        let expectedRefreshToken = "refresh-jwt"
        let sut = try Self.makeSUT(
            statusCode: successStatusCode,
            responseBody: TokensResponseFixture.valid(accessToken: expectedAccessToken, refreshToken: expectedRefreshToken)
        )

        let sessionTokens = try await sut.unregister(id: UserWalletId.fake, shouldEraseSocialLoginData: false)

        #expect(sessionTokens.accessToken.jwt == expectedAccessToken)
        #expect(sessionTokens.refreshToken?.jwt == expectedRefreshToken)
    }

    @Test
    func unregisterThrowsUnregisterFailedOnUnexpectedResponseBody() async throws {
        let anySuccessStatusCode = 200
        let sut = try Self.makeSUT(
            statusCode: anySuccessStatusCode,
            responseBody: TokensResponseFixture.invalidWithUnixTimestampDateFormat
        )

        let error = try await #require(throws: UserWalletRegistrationClientError.self) {
            _ = try await sut.unregister(id: UserWalletId.fake, shouldEraseSocialLoginData: false)
        }

        guard case .unregisterFailed = error else {
            Issue.record("Expected .unregisterFailed, got \(error)")
            return
        }
    }

    @Test
    func unregisterThrowsWasNotRegisteredFor404WithMatchingProblemDetail() async throws {
        let sut = try Self.makeSUT(statusCode: 404, responseBody: Self.problemDetailBody(.walletNotRegistered))

        let error = try await #require(throws: UserWalletRegistrationClientError.self) {
            _ = try await sut.unregister(id: UserWalletId.fake, shouldEraseSocialLoginData: false)
        }

        guard case .wasNotRegistered = error else {
            Issue.record("Expected .wasNotRegistered, got \(error)")
            return
        }
    }

    @Test
    func unregisterThrowsUnregisterFailedFor404WithNonMatchingProblemDetail() async throws {
        let sut = try Self.makeSUT(statusCode: 404, responseBody: Self.problemDetailBody(.walletAlreadyRegistered))

        let error = try await #require(throws: UserWalletRegistrationClientError.self) {
            _ = try await sut.unregister(id: UserWalletId.fake, shouldEraseSocialLoginData: false)
        }

        guard case .unregisterFailed = error else {
            Issue.record("Expected .unregisterFailed, got \(error)")
            return
        }
    }

    @Test(arguments: StatusCodes.error)
    func unregisterThrowsUnregisterFailedOnErrorStatusCode(errorStatusCode: Int) async throws {
        let sut = try Self.makeSUT(statusCode: errorStatusCode)

        let error = try await #require(throws: UserWalletRegistrationClientError.self) {
            _ = try await sut.unregister(id: UserWalletId.fake, shouldEraseSocialLoginData: false)
        }

        guard case .unregisterFailed = error else {
            Issue.record("Expected .unregisterFailed, got \(error)")
            return
        }
    }
}

// MARK: - Factory methods

extension MoyaUserWalletRegistrationClientTests {
    private static func makeSUT(
        statusCode: Int,
        responseBody: String = "",
        sourceLocation: SourceLocation = #_sourceLocation
    ) throws -> some UserWalletRegistrationClient {
        try makeSUT(
            endpointClosure: { target in
                Endpoint.stub(target: target, statusCode: statusCode, responseBody: responseBody)
            },
            nonceEndpointClosure: { target in
                Endpoint.stub(target: target, statusCode: statusCode, responseBody: responseBody)
            },
            sourceLocation: sourceLocation
        )
    }

    private static func makeSUT(
        networkError: some Error,
        sourceLocation: SourceLocation = #_sourceLocation
    ) throws -> some UserWalletRegistrationClient {
        try makeSUT(
            endpointClosure: { target in
                Endpoint.stub(target: target, sampleResponse: .networkError(networkError as NSError))
            },
            nonceEndpointClosure: { target in
                Endpoint.stub(target: target, sampleResponse: .networkError(networkError as NSError))
            },
            sourceLocation: sourceLocation
        )
    }

    private static func makeSUT(
        endpointClosure: @escaping MoyaProvider<UserWalletTarget>.EndpointClosure,
        nonceEndpointClosure: @escaping MoyaProvider<BackendAuthenticationTarget>.EndpointClosure,
        sourceLocation: SourceLocation = #_sourceLocation
    ) throws -> some UserWalletRegistrationClient {
        let provider = MoyaProvider<UserWalletTarget>(
            endpointClosure: endpointClosure,
            stubClosure: MoyaProvider.immediatelyStub
        )

        let nonceProvider = MoyaProvider<BackendAuthenticationTarget>(
            endpointClosure: nonceEndpointClosure,
            stubClosure: MoyaProvider.immediatelyStub
        )

        let anyBaseURL = try #require(URL(string: "https://example.com"), sourceLocation: sourceLocation)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .customISO8601

        return MoyaUserWalletRegistrationClient(
            provider: provider,
            nonceProvider: nonceProvider,
            baseURL: anyBaseURL,
            decoder: decoder
        )
    }
}

// MARK: - Fixtures

extension MoyaUserWalletRegistrationClientTests {
    private enum StatusCodes {
        static let success = [200, 201, 202, 203, 204, 205, 206, 207, 208, 226]
        static let error = [400, 401, 403, 404, 500, 501, 512]
    }

    private static func problemDetailBody(_ response: ProblemDetailDTO.Response) -> String {
        #"{"detail":"\#(response.detail)"}"#
    }
}
