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
import TangemAssets

enum KYCServiceError: Error {
    case sdkIsNotReady
    case alreadyPresent
}

public final class KYCService {
    private let sdk: SNSMobileSDK
    private let kycStepSubject = CurrentValueSubject<KYCStep?, Never>(nil)

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
        sdk.theme.fonts.headline1 = UIFonts.Bold.title1 // Title
        sdk.theme.fonts.headline2 = UIFonts.Bold.footnote // Section title (e.g. "Select country where your ID document was issued")
        sdk.theme.fonts.subtitle2 = UIFonts.Regular.subheadline // Subtitle
        sdk.theme.fonts.subtitle1 = UIFonts.Regular.callout // Action button
        sdk.theme.fonts.caption = UIFonts.Regular.caption1
        sdk.theme.fonts.body = UIFonts.Regular.subheadline

        sdk.theme.colors.contentStrong = UIColor(hex: "#1E1E1E") // Title
        sdk.theme.colors.contentNeutral = UIColor(hex: "#656565") // Subtitle
        sdk.theme.colors.contentWeak = UIColor(hex: "#1E1E1E") // Status card image color
        sdk.theme.colors.contentWarning = UIColor(hex: "#1E1E1E") // Status card image color when submitted
        sdk.theme.colors.primaryButtonContent = UIColor(hex: "#FFFFFF")
        sdk.theme.colors.primaryButtonBackground = UIColor(hex: "#1E1E1E")
        sdk.theme.colors.primaryButtonBackgroundDisabled = UIColor(hex: "#1E1E1E").withAlphaComponent(0.5)
        sdk.theme.colors.primaryButtonBackgroundHighlighted = UIColor(hex: "#1E1E1E").withAlphaComponent(0.8)
        sdk.theme.colors.fieldBorder = UIColor(hex: "#0099FF")

        sdk.theme.metrics.verificationStepCardStyle = .plain
        sdk.theme.metrics.documentTypeCardStyle = .plain
        sdk.theme.metrics.sectionHeaderAlignment = .natural
        sdk.theme.metrics.buttonCornerRadius = 14

//        sdk.theme.images.iconDisclosure = UIImage()

//        sdk.theme.images.verificationStepIcons = [
//            .applicantData: UIImage(),
//            .default: UIImage(),
//            .ekyc: UIImage(),
//            .emailVerification: UIImage(),
//            .esign: UIImage(),
//            .identity: UIImage(),
//            .identity2: UIImage(),
//            .identity3: UIImage(),
//            .identity4: UIImage(),
//            .phoneVerification: UIImage(),
//            .proofOfResidence: UIImage(),
//            .proofOfResidence2: UIImage(),
//            .questionnaire: UIImage(),
//            .selfie: UIImage(),
//            .selfie2: UIImage(),
//            .videoIdent: UIImage(),
//        ]
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

extension UIColor {
    convenience init(hex: String) {
        self.init(cgColor: Color(hex: hex)!.cgColor!)
    }
}
