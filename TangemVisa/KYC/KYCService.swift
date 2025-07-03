//
//  KYCService.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import IdensicMobileSDK
import SwiftUI

enum KYCServiceError: Error {
    case sdkIsNotReady
    case alreadyPresent
}

public final class KYCService {
    private let sdk: SNSMobileSDK
    private let kycStepSubject = CurrentValueSubject<KYCStep?, Never>(nil)

    @MainActor
    @discardableResult
    private init(token: String, locale: String, getToken: @escaping () async -> String?) async throws {
        guard Self.shared == nil else {
            throw KYCServiceError.alreadyPresent
        }

        sdk = SNSMobileSDK(
            accessToken: token,
            environment: .production
        )
        sdk.locale = locale

        guard sdk.isReady else {
            throw KYCServiceError.sdkIsNotReady
        }

        // Holds a reference to itself to manage it's own lifecycle.
        // Reference is being released after KYC flow is finished
        Self.shared = self
        sdk.onDidDismiss { _ in
            Self.shared = nil
        }

        sdk.tokenExpirationHandler { onComplete in
            Task {
                onComplete(await getToken())
            }
        }

        sdk.onEvent { [weak kycStepSubject] _, event in
            guard let step = event.kycStep else { return }
            kycStepSubject?.send(step)
        }

        sdk.verificationHandler { isApproved in
            // [REDACTED_TODO_COMMENT]
            // [REDACTED_INFO]
        }

        configureSDKTheme()

        // Swizzle lifecycle methods to override SDK view controllers behavior
        UIViewController.toggleKYCSDKControllersSwizzling()
        sdk.present()
    }

    deinit {
        // Unswizzle methods after KYC flow is finished
        UIViewController.toggleKYCSDKControllersSwizzling()
    }

    private func configureSDKTheme() {
        // [REDACTED_TODO_COMMENT]
        // [REDACTED_INFO]
//        sdk.theme.fonts.headline1 = .systemFont(ofSize: 28, weight: .bold)
//        sdk.theme.fonts.subtitle2 = .systemFont(ofSize: 15, weight: .regular)
//        sdk.theme.fonts.subtitle1 = .systemFont(ofSize: 16, weight: .medium)
//
//        sdk.theme.colors.contentStrong = .hex("#1E1E1E")
//        sdk.theme.colors.contentNeutral = .hex("#656565")
//        sdk.theme.colors.primaryButtonContent = .hex("#FFFFFF")
//        sdk.theme.colors.primaryButtonBackground = .hex("#1E1E1E")
    }
}

extension KYCService {
    private(set) static var shared: KYCService?

    var kycStepPublisher: AnyPublisher<KYCStep, Never> {
        kycStepSubject
            .compactMap { $0 }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    func dismiss() {
        sdk.dismiss()
    }
}

public extension KYCService {
    static func start(token: String, locale: String, getToken: @escaping () async -> String?) async throws {
        try await KYCService(token: token, locale: locale, getToken: getToken)
    }
}
