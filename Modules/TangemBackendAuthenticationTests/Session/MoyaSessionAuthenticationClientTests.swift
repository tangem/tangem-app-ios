//
//  MoyaSessionAuthenticationClientTests.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import Testing
import TangemFoundation
@testable import TangemBackendAuthentication

@Suite(.tags(.backendAuthentication))
struct MoyaSessionAuthenticationClientTests {
    @Test(arguments: StatusCodes.success)
    func requestCipheredNonceReturnsCipheredNonceOnSuccessStatusCode(successStatusCode: Int) async throws {
        let sut = try Self.makeSUT(statusCode: successStatusCode, responseBody: NonceResponse.valid)
        let cipheredNonce = try await sut.requestCipheredNonce(devicePublicKey: .fake)

        #expect(cipheredNonce == "ciphered-value")
    }

    @Test
    func requestCipheredNonceFailsOnUnexpectedResponseBody() async throws {
        let anySuccessStatusCode = 200
        let sut = try Self.makeSUT(statusCode: anySuccessStatusCode, responseBody: NonceResponse.invalid)

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
        let sut = try Self.makeSUT(statusCode: successStatusCode, responseBody: TokensResponse.valid)

        let sessionTokens = try await sut.authenticate(
            devicePublicKey: .fake,
            decryptedNonce: "decrypted-nonce",
            metadata: .fake,
            signature: .fake,
            attestationToken: nil
        )

        #expect(sessionTokens.accessToken.jwt == "access-jwt")
    }

    @Test
    func authenticateThrowsAuthenticateFailedOnUnexpectedResponseBody() async throws {
        let anySuccessStatusCode = 200
        let sut = try Self.makeSUT(statusCode: anySuccessStatusCode, responseBody: TokensResponse.invalidWithUnixTimestampDateFormat)

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
        let sut = try Self.makeSUT(
            statusCode: successStatusCode,
            responseBody: TokensResponse.valid,
            headersSpy: { actualHeaders in
                #expect(actualHeaders?["Authorization"] == "DPoP access-jwt")
                #expect(actualHeaders?["DPoP"] != nil)
            }
        )

        let sessionTokens = try await sut.refresh(refreshToken: "refresh-jwt", accessToken: "access-jwt")

        #expect(sessionTokens.accessToken.jwt == "access-jwt")
    }

    @Test
    func refreshThrowsRefreshFailedOnUnexpectedResponseBody() async throws {
        let anySuccessStatusCode = 200
        let sut = try Self.makeSUT(statusCode: anySuccessStatusCode, responseBody: TokensResponse.invalidWithUnixTimestampDateFormat)

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
        let provider = MoyaProvider<BackendAuthenticationTarget>(
            endpointClosure: { target in
                headersSpy?(target.headers)
                return Self.makeEndpoint(for: target, statusCode: statusCode, responseBody: responseBody)
            },
            stubClosure: MoyaProvider.immediatelyStub
        )

        let anyBaseURL = try #require(URL(string: "https://example.com"), sourceLocation: sourceLocation)

        let dPoPProofGenerator = DPoPProofGenerator(
            deviceKeyManager: DeviceKeyManager(privateKeyRepository: FakeDevicePrivateKeyRepository())
        )

        return MoyaSessionAuthenticationClient(provider: provider, baseURL: anyBaseURL, dPoPProofGenerator: dPoPProofGenerator)
    }

    private static func makeEndpoint(for target: BackendAuthenticationTarget, statusCode: Int, responseBody: String) -> Endpoint {
        Endpoint(
            url: target.baseURL.appendingPathComponent(target.path).absoluteString,
            sampleResponseClosure: { .networkResponse(statusCode, Data(responseBody.utf8)) },
            method: target.method,
            task: target.task,
            httpHeaderFields: target.headers
        )
    }
}

// MARK: - Fixtures

extension MoyaSessionAuthenticationClientTests {
    private enum StatusCodes {
        static let success = [200, 201, 202, 203, 204, 205, 206, 207, 208, 226]
        static let error = [400, 402, 404, 500, 501, 512]
        static let authenticationRejection = [401, 403]
    }

    private enum NonceResponse {
        static let valid = #"{"cipheredNonce":"ciphered-value","expiresAt":"2026-01-01T00:00:00Z"}"#
        static let invalid = #"{"beep-bop":67}"#
    }

    private enum TokensResponse {
        static let valid = """
        {
            "accessToken": "access-jwt",
            "accessTokenExpiresAt": "2026-01-01T00:00:00Z",
            "refreshToken": "refresh-jwt",
            "refreshTokenExpiresAt": "2026-02-01T00:00:00Z",
            "walletIds": []
        }
        """

        static let invalidWithUnixTimestampDateFormat = """
        {
            "accessToken": "access-jwt",
            "accessTokenExpiresAt": "1767225600",
            "refreshToken": "refresh-jwt",
            "refreshTokenExpiresAt": "1767225600",
            "walletIds": []
        }
        """
    }
}

private extension DeviceSignature {
    static var fake: DeviceSignature {
        get throws(DeviceSignature.RawRepresentationFormatError) {
            try DeviceSignature(
                derRepresentation: Data([0x01, 0x02, 0x03]),
                rawRepresentation: Data(repeating: 0xAB, count: 64)
            )
        }
    }
}
