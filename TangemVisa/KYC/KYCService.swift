//
//  KYCService.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

#if ALPHA || BETA || DEBUG
import Combine
import SwiftUI
import TangemAssets
import IdensicMobileSDK

enum KYCServiceError: Error {
    case sdkIsNotReady
    case alreadyPresent
}

public final class KYCService {
    private let sdk: SNSMobileSDK

    @MainActor
    @discardableResult
    private init(getToken: @escaping () async throws -> VisaKYCAccessTokenResponse) async throws {
        guard Self.shared == nil else {
            throw KYCServiceError.alreadyPresent
        }

        let kycResponse = try await getToken()
        sdk = SNSMobileSDK(
            accessToken: kycResponse.token,
            environment: .production
        )
        sdk.locale = kycResponse.locale

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
                onComplete(try? await getToken().token)
            }
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
        sdk.theme.fonts.headline1 = UIFonts.Bold.title1 // Title
        sdk.theme.fonts.headline2 = UIFonts.Bold.footnote // Section title (e.g. "Select country where your ID document was issued")
        sdk.theme.fonts.subtitle2 = UIFonts.Regular.subheadline // Subtitle
        sdk.theme.fonts.subtitle1 = UIFonts.Regular.callout // Action button
        sdk.theme.fonts.caption = UIFonts.Regular.caption1
        sdk.theme.fonts.body = UIFonts.Regular.subheadline

        sdk.theme.colors.contentStrong = UIColor(Colors.Text.primary1) // Title
        sdk.theme.colors.contentNeutral = UIColor(Colors.Text.secondary) // Subtitle
        sdk.theme.colors.contentSuccess = UIColor(Colors.Button.positive).withAlphaComponent(0.33) // Status color when accepted
        sdk.theme.colors.primaryButtonContent = UIColor(Colors.Text.primary2)
        sdk.theme.colors.primaryButtonBackground = UIColor(Colors.Text.primary1)
        sdk.theme.colors.primaryButtonBackgroundDisabled = UIColor(Colors.Text.primary1).withAlphaComponent(0.5)
        sdk.theme.colors.primaryButtonBackgroundHighlighted = UIColor(Colors.Text.primary1).withAlphaComponent(0.8)
        sdk.theme.colors.fieldBorder = UIColor(Colors.Button.positive)

        sdk.theme.metrics.verificationStepCardStyle = .plain
        sdk.theme.metrics.documentTypeCardStyle = .plain
        sdk.theme.metrics.sectionHeaderAlignment = .natural
        sdk.theme.metrics.buttonCornerRadius = 14

        sdk.theme.images.verificationStepIcons = [
            .applicantData: Assets.Kyc.profileDetails.uiImage,
            .emailVerification: Assets.Kyc.emailVerification.uiImage,
            .identity: Assets.Kyc.identityDocument.uiImage,
            .identity2: Assets.Kyc.identityDocument.uiImage,
            .identity3: Assets.Kyc.identityDocument.uiImage,
            .identity4: Assets.Kyc.identityDocument.uiImage,
            .phoneVerification: Assets.Kyc.phoneVerification.uiImage,
            .proofOfResidence: Assets.Kyc.proofOfAddress.uiImage,
            .proofOfResidence2: Assets.Kyc.proofOfAddress.uiImage,
            .questionnaire: Assets.Kyc.questionnaire.uiImage,
            .selfie: Assets.Kyc.selfie.uiImage,
            .selfie2: Assets.Kyc.selfie.uiImage,
        ]
    }
}

extension KYCService {
    private(set) static var shared: KYCService?

    @objc
    func dismiss() {
        sdk.dismiss()
    }
}

public extension KYCService {
    static func start(getToken: @escaping () async throws -> VisaKYCAccessTokenResponse) async throws {
        try await KYCService(getToken: getToken)
    }
}
#endif // ALPHA || BETA || DEBUG
