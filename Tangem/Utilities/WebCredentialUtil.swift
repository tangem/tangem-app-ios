//
//  WebCredentialUtil.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import AuthenticationServices
import Security
import UIKit
import TangemFoundation
import TangemUIUtils

enum WebCredentialUtil {
    private static let domain = "tangem.com"

    /// Saves credential data to the user's password manager through the `webcredentials` associated domain.
    static func save(_ savedCredential: SavedCredential) async throws {
        guard let credential = try? JSONDecoder().decode(Credential.self, from: savedCredential.data) else {
            throw SaveError.invalidData
        }

        try await save(user: credential.user, password: credential.password)
        savedCredential.secureErase()
    }

    private static func save(user: String, password: String) async throws {
        if #available(iOS 26.2, *) {
            try await saveToCredentialManager(user: user, password: password)
        } else {
            try await addSharedWebCredential(user: user, password: password)
        }
    }

    @available(iOS 26.2, *)
    private static func saveToCredentialManager(user: String, password: String) async throws {
        guard let anchor = await UIApplication.mainWindow else {
            throw SaveError.anchorNotFound
        }

        await waitWhilePresentationIsBusy(in: anchor)

        let scope = ASAutoFillURLScope(host: domain)
        let credential = ASPasswordCredential(user: user, password: password)

        try await ASCredentialDataManager().save(password: credential, for: scope, anchor: anchor)
    }

    @MainActor
    private static func waitWhilePresentationIsBusy(in window: UIWindow, timeout: TimeInterval = 1) async {
        let pollStep: TimeInterval = 0.1
        var elapsed: TimeInterval = 0

        while window.rootViewController?.presentedViewController != nil, elapsed < timeout {
            try? await Task.sleep(for: .seconds(pollStep))
            elapsed += pollStep
        }
    }

    @available(iOS, deprecated: 100000.0, message: "Legacy path, replaced by ASCredentialDataManager on iOS 26.2+")
    private static func addSharedWebCredential(user: String, password: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            SecAddSharedWebCredential(
                domain as CFString,
                user as CFString,
                password as CFString
            ) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}

// MARK: - Private types

private extension WebCredentialUtil {
    struct Credential: Codable {
        let user: String
        let password: String
    }
}

// MARK: - Types

extension WebCredentialUtil {
    final class SavedCredential {
        private(set) var data: Data

        init(user: String, password: String) throws {
            let credential = Credential(user: user, password: password)
            guard let data = try? JSONEncoder().encode(credential) else {
                throw SaveError.invalidParams
            }
            self.data = data
        }

        deinit {
            secureErase()
        }

        func secureErase() {
            data.secureErase()
        }
    }

    enum SaveError: Error {
        case invalidParams
        case invalidData
        case anchorNotFound
    }
}
