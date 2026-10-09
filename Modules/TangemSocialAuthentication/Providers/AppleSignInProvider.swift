//
//  AppleSignInProvider.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import AuthenticationServices
import CryptoKit
import Foundation
import TangemFoundation

public actor AppleSignInProvider {
    public typealias PresentationAnchorProvider = @MainActor () -> ASPresentationAnchor

    private let presentationAnchorProvider: PresentationAnchorProvider
    private let taskProcessor = SingleTaskProcessor<SocialAuthCredentials, SocialAuthError>()

    public init(presentationAnchorProvider: @escaping PresentationAnchorProvider) {
        self.presentationAnchorProvider = presentationAnchorProvider
    }
}

// MARK: - SocialAuthSignInProvider

extension AppleSignInProvider: SocialAuthSignInProvider {
    public func signIn(nonce: String) async throws(SocialAuthError) -> SocialAuthCredentials {
        try await taskProcessor.execute { [presentationAnchorProvider] () throws(SocialAuthError) in
            let session = AppleSignInSession(nonce: nonce, presentationAnchorProvider: presentationAnchorProvider)

            do {
                return try await session.authorize()
            } catch let error as SocialAuthError {
                throw error
            } catch {
                throw .authorizationFailed(underlying: error)
            }
        }
    }
}

// MARK: - AppleSignInSession

private final class AppleSignInSession: NSObject {
    private let nonce: String
    private let presentationAnchorProvider: AppleSignInProvider.PresentationAnchorProvider
    private var continuation: CheckedContinuation<SocialAuthCredentials, Error>?

    private var controller: ASAuthorizationController?
    private var presentationAnchor: ASPresentationAnchor?

    init(
        nonce: String,
        presentationAnchorProvider: @escaping AppleSignInProvider.PresentationAnchorProvider
    ) {
        self.nonce = nonce
        self.presentationAnchorProvider = presentationAnchorProvider
    }

    func authorize() async throws -> SocialAuthCredentials {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.email]
        request.nonce = hashedNonce(nonce)

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation

            Task { @MainActor in
                self.presentationAnchor = self.presentationAnchorProvider()

                let controller = ASAuthorizationController(authorizationRequests: [request])
                controller.delegate = self
                controller.presentationContextProvider = self
                self.controller = controller
                controller.performRequests()
            }
        }
    }

    private func hashedNonce(_ nonce: String) -> String {
        Data(SHA256.hash(data: Data(nonce.utf8))).base64EncodedString()
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AppleSignInSession: ASAuthorizationControllerDelegate {
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        defer { continuation = nil }

        guard
            let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
            let tokenData = credential.identityToken
        else {
            SocialAuthLogger.error("Apple sign in returned an invalid credential", error: SocialAuthError.invalidCredential)
            continuation?.resume(throwing: SocialAuthError.invalidCredential)
            return
        }

        continuation?.resume(returning: SocialAuthCredentials(
            identityTokenData: tokenData,
            nonce: nonce
        ))
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        let mappedError = SocialAuthError(appleAuthorizationError: error)

        if case .cancelled = mappedError {
            SocialAuthLogger.info("Apple sign in cancelled by the user")
        } else {
            SocialAuthLogger.error("Apple sign in failed", error: error)
        }

        continuation?.resume(throwing: mappedError)
        continuation = nil
    }
}

// MARK: - Error mapping

private extension SocialAuthError {
    init(appleAuthorizationError error: Error) {
        if let authorizationError = error as? ASAuthorizationError, authorizationError.code == .canceled {
            self = .cancelled
        } else {
            self = .authorizationFailed(underlying: error)
        }
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension AppleSignInSession: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        presentationAnchor ?? ASPresentationAnchor()
    }
}
