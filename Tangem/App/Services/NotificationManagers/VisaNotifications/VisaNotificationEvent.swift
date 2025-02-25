//
//  VisaNotificationEvent.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

enum VisaNotificationEvent: Hashable {
    case missingRequiredBlockchain
    case notValidBlockchain
    case failedToLoadPaymentAccount
    case missingPublicKey
    case failedToGenerateAddress
    case onboardingAccountActivationInfo
    case authorizationError
    case missingValidRefreshToken
    case missingCardId
    case invalidConfig
    case invalidActivationState
}

extension VisaNotificationEvent: NotificationEvent {
    var title: NotificationView.Title? {
        switch self {
        case .missingRequiredBlockchain, .notValidBlockchain, .failedToLoadPaymentAccount, .missingPublicKey, .failedToGenerateAddress, .authorizationError, .missingCardId, .invalidConfig, .invalidActivationState:
            return .string("Error")
        case .missingValidRefreshToken:
            return .string("Attention")
        case .onboardingAccountActivationInfo:
            return nil
        }
    }

    var description: String? {
        switch self {
        case .missingRequiredBlockchain:
            return "Failed to find required WalletManager"
        case .notValidBlockchain:
            return "WalletManager doesn't supported Smart Contract interaction"
        case .failedToLoadPaymentAccount:
            return "Failed to find Payment Account address in bridge"
        case .missingPublicKey:
            return "Failed to find Public key in keys repository"
        case .failedToGenerateAddress:
            return "Failed to generate address with provided Public key"
        case .onboardingAccountActivationInfo:
            return "Please choose the wallet you started the registration process with to sign the transaction for creating your account on the Blockchain"
        case .authorizationError:
            return "Failed to authorize, please contact support"
        case .missingValidRefreshToken:
            return "To access this wallet you need to scan card first"
        case .missingCardId:
            return "Failed to identify card, please contact support"
        case .invalidConfig:
            return "Failed to identify card configuration, please contact support"
        case .invalidActivationState:
            return "This card is not available for use, please contact support"
        }
    }

    var colorScheme: NotificationView.ColorScheme {
        return .secondary
    }

    var icon: NotificationView.MessageIcon {
        switch self {
        case .missingRequiredBlockchain, .notValidBlockchain, .failedToLoadPaymentAccount, .missingPublicKey, .failedToGenerateAddress, .authorizationError, .missingCardId, .invalidConfig, .invalidActivationState:
            return .init(iconType: .image(Assets.redCircleWarning.image))
        case .missingValidRefreshToken:
            return .init(iconType: .image(Assets.warningIcon.image))
        case .onboardingAccountActivationInfo:
            return .init(iconType: .image(Assets.blueCircleWarning.image))
        }
    }

    var severity: NotificationView.Severity {
        return .critical
    }

    var isDismissable: Bool {
        return false
    }

    var buttonAction: NotificationButtonAction? {
        switch self {
        case .missingValidRefreshToken:
            return .init(.scanCard, withLoader: true)
        default:
            return nil
        }
    }
}

// MARK: - Analytics

extension VisaNotificationEvent {
    var analyticsEvent: Analytics.Event? {
        nil
    }

    var analyticsParams: [Analytics.ParameterKey: String] {
        [:]
    }

    var isOneShotAnalyticsEvent: Bool {
        false
    }
}
