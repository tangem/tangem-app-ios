//
//  TokenNotificationEvent.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import SwiftUI
import TangemAssets
import struct TangemUI.TokenIconInfo
import TangemAccessibilityIdentifiers

enum TokenNotificationEvent: Hashable {
    case networkUnreachable(currencySymbol: String)
    case networkNotUpdated(lastUpdatedDate: Date)
    case rentFee(rentMessage: String)
    case noAccount(message: String)
    case existentialDepositWarning(message: String)
    case notEnoughFeeForTransaction(configuration: NotEnoughFeeConfiguration)
    case bnbBeaconChainRetirement
    case hasUnfulfilledRequirements(configuration: UnfulfilledRequirementsConfiguration)
    case staking(tokenIconInfo: TokenIconInfo, earnUpToFormatted: String)
    case manaLevel(currentMana: String, maxMana: String)
    case maticMigration
    case cloreMigration
}

extension TokenNotificationEvent: NotificationEvent {
    var title: NotificationView.Title? {
        switch self {
        case .networkUnreachable:
            return .string(Localization.warningNetworkUnreachableTitle)
        case .networkNotUpdated:
            return .none
        case .rentFee:
            return .string(Localization.warningRentFeeTitle)
        case .noAccount:
            return .string(Localization.warningNoAccountTitle)
        case .existentialDepositWarning:
            return .string(Localization.warningExistentialDepositTitle)
        case .notEnoughFeeForTransaction(let configuration):
            return .string(Localization.warningSendBlockedFundsForFeeTitle(configuration.feeAmountTypeName))
        case .bnbBeaconChainRetirement:
            return .string(Localization.warningBeaconChainRetirementTitle)
        case .hasUnfulfilledRequirements(configuration: .missingHederaTokenAssociation):
            return .string(Localization.warningHederaMissingTokenAssociationTitle)
        case .hasUnfulfilledRequirements(configuration: .incompleteKaspaTokenTransaction):
            return .string(Localization.warningKaspaUnfinishedTokenTransactionTitle)
        case .hasUnfulfilledRequirements(configuration: .missingTokenTrustline):
            return .string(Localization.warningTokenTrustlineTitle)
        case .staking:
            return .string(Localization.tokenDetailsStakingBlockTitle)
        case .manaLevel:
            return .string(Localization.koinosManaLevelTitle)
        case .maticMigration:
            return .string(Localization.warningMaticMigrationTitle)
        case .cloreMigration:
            return .string(Localization.warningCloreMigrationTitle)
        }
    }

    var description: String? {
        switch self {
        case .networkUnreachable:
            return Localization.warningNetworkUnreachableMessage
        case .networkNotUpdated(let date):
            // Formatting will be update
            // [REDACTED_TODO_COMMENT]
            let formatted = date.formatted(date: .abbreviated, time: .shortened)
            return Localization.warningLastBalanceUpdatedTime(formatted)
        case .rentFee(let message):
            return message
        case .noAccount(let message):
            return message
        case .existentialDepositWarning(let message):
            return message
        case .notEnoughFeeForTransaction(let configuration):
            return Localization.warningSendBlockedFundsForFeeMessage(
                configuration.transactionAmountTypeName,
                configuration.networkName,
                configuration.transactionAmountTypeName,
                configuration.feeAmountTypeName,
                configuration.feeAmountTypeCurrencySymbol
            )
        case .bnbBeaconChainRetirement:
            return Localization.warningBeaconChainRetirementContent
        case .hasUnfulfilledRequirements(configuration: .missingHederaTokenAssociation(let associationFee)):
            guard let associationFee else {
                return Localization.warningHederaMissingTokenAssociationMessageBrief
            }

            return Localization.warningHederaMissingTokenAssociationMessage(
                associationFee.formattedValue,
                associationFee.currencySymbol
            )
        case .hasUnfulfilledRequirements(configuration: .incompleteKaspaTokenTransaction(let revealTransaction)):
            return Localization.warningKaspaUnfinishedTokenTransactionMessage(
                revealTransaction.formattedValue,
                revealTransaction.currencySymbol
            )
        case .hasUnfulfilledRequirements(configuration: .missingTokenTrustline(let trustlineInfo)):
            return Localization.warningTokenTrustlineSubtitle(trustlineInfo.reserveCurrencySymbol, trustlineInfo.reserveAmount)
        case .staking:
            return Localization.stakingNotificationEarnRewardsText
        case .manaLevel(let currentMana, let maxMana):
            return Localization.koinosManaLevelDescription(currentMana, maxMana)
        case .maticMigration:
            return Localization.warningMaticMigrationMessage
        case .cloreMigration:
            return Localization.warningCloreMigrationDescription
        }
    }

    var colorScheme: NotificationView.ColorScheme {
        switch self {
        case .networkUnreachable,
             .networkNotUpdated,
             .rentFee,
             .existentialDepositWarning,
             .noAccount,
             .bnbBeaconChainRetirement,
             .manaLevel,
             .maticMigration:
            return .secondary
        // One white notification will be added later
        case .notEnoughFeeForTransaction,
             .hasUnfulfilledRequirements(configuration: .missingHederaTokenAssociation),
             .hasUnfulfilledRequirements(configuration: .incompleteKaspaTokenTransaction),
             .hasUnfulfilledRequirements(configuration: .missingTokenTrustline),
             .staking,
             .cloreMigration:
            return .primary
        }
    }

    var icon: NotificationView.MessageIcon {
        switch self {
        case .networkNotUpdated:
            return .init(iconType: .image(Assets.failedCloud.image), color: Colors.Icon.attention)
        case .networkUnreachable,
             .bnbBeaconChainRetirement,
             .maticMigration,
             .cloreMigration:
            return .init(iconType: .image(Assets.attention.image))
        case .rentFee, .noAccount, .existentialDepositWarning, .manaLevel:
            return .init(iconType: .image(Assets.blueCircleWarning.image))
        case .notEnoughFeeForTransaction(let configuration):
            return .init(iconType: .image(configuration.feeAmountTypeIconAsset.image))
        case .hasUnfulfilledRequirements(configuration: .missingHederaTokenAssociation):
            return .init(iconType: .image(Tokens.hederaFill.image))
        case .hasUnfulfilledRequirements(configuration: .incompleteKaspaTokenTransaction):
            return .init(iconType: .image(Assets.redCircleWarning.image))
        case .hasUnfulfilledRequirements(configuration: .missingTokenTrustline(let trustlineInfo)):
            return .init(iconType: .image(trustlineInfo.icon.image))
        case .staking(let tokenIconInfo, _):
            return .init(iconType: .icon(tokenIconInfo))
        }
    }

    var severity: NotificationView.Severity {
        switch self {
        case .noAccount,
             .rentFee,
             .existentialDepositWarning,
             .staking,
             .manaLevel,
             .maticMigration,
             .cloreMigration:
            return .info
        case .networkUnreachable,
             .networkNotUpdated,
             .notEnoughFeeForTransaction,
             .bnbBeaconChainRetirement,
             .hasUnfulfilledRequirements(configuration: .missingHederaTokenAssociation),
             .hasUnfulfilledRequirements(configuration: .incompleteKaspaTokenTransaction),
             .hasUnfulfilledRequirements(configuration: .missingTokenTrustline):
            return .warning
        }
    }

    var isDismissable: Bool {
        switch self {
        case .rentFee,
             .hasUnfulfilledRequirements(configuration: .incompleteKaspaTokenTransaction):
            return true
        case .networkUnreachable,
             .networkNotUpdated,
             .existentialDepositWarning,
             .notEnoughFeeForTransaction,
             .noAccount,
             .bnbBeaconChainRetirement,
             .hasUnfulfilledRequirements(configuration: .missingHederaTokenAssociation),
             .hasUnfulfilledRequirements(configuration: .missingTokenTrustline),
             .staking,
             .manaLevel,
             .maticMigration,
             .cloreMigration:
            return false
        }
    }

    var buttonAction: NotificationButtonAction? {
        switch self {
        // One notification with button action will be added later
        case .networkUnreachable,
             .networkNotUpdated,
             .rentFee,
             .existentialDepositWarning,
             .noAccount,
             .bnbBeaconChainRetirement,
             .manaLevel,
             .maticMigration:
            return nil
        case .notEnoughFeeForTransaction(let configuration):
            let currencySymbol = configuration.currencyButtonTitle ?? configuration.feeAmountTypeCurrencySymbol
            if configuration.isFeeCurrencyPurchaseAllowed {
                return .init(.openFeeCurrency(currencySymbol: currencySymbol))
            }

            return nil
        case .hasUnfulfilledRequirements(.missingHederaTokenAssociation):
            return .init(.addHederaTokenAssociation)
        case .hasUnfulfilledRequirements(configuration: .incompleteKaspaTokenTransaction):
            return .init(.retryKaspaTokenTransaction)
        case .hasUnfulfilledRequirements(configuration: .missingTokenTrustline(let config)):
            if config.canPerformAction {
                return .init(.addTokenTrustline, withLoader: true, isDisabled: config.trustlineOperationInProgress)
            }
            return nil
        case .staking:
            return .init(.stake)
        case .cloreMigration:
            return .init(.openCloreMigration)
        }
    }
}

// MARK: - Auxiliary types

extension TokenNotificationEvent {
    typealias NotEnoughFeeConfiguration = SendingRestrictions.NotEnoughFeeConfiguration

    enum UnfulfilledRequirementsConfiguration: Hashable {
        /// `formattedValue` is a formatted string for the value denominated in HBARs.
        struct HederaTokenAssociationFee: Hashable {
            let formattedValue: String
            let currencySymbol: String
        }

        /// `onTransactionDiscard` callback is intentionally ignored by `Equatable` and `Hashable` implementations.
        struct KaspaTokenRevealTransaction: Hashable {
            let formattedValue: String
            let currencySymbol: String

            /// Use for only analytics parameter value
            let blockchainName: String

            let onTransactionDiscard: () -> Void

            static func == (lhs: Self, rhs: Self) -> Bool {
                return lhs.formattedValue == rhs.formattedValue && lhs.currencySymbol == rhs.currencySymbol
            }

            func hash(into hasher: inout Hasher) {
                hasher.combine(formattedValue)
                hasher.combine(currencySymbol)
            }
        }

        struct MissingTrustlineInfo: Hashable {
            let reserveCurrencySymbol: String
            let reserveAmount: String
            let icon: ImageType
            let trustlineOperationInProgress: Bool
            let canPerformAction: Bool
        }

        /// `associationFee` fetched asynchronously and therefore may be absent in some cases.
        case missingHederaTokenAssociation(associationFee: HederaTokenAssociationFee?)
        case incompleteKaspaTokenTransaction(revealTransaction: KaspaTokenRevealTransaction)
        case missingTokenTrustline(MissingTrustlineInfo)
    }

    struct YieldAvailableConfiguration: Hashable {
        let apy: String
    }
}

// MARK: Analytics info

extension TokenNotificationEvent {
    var analyticsEvent: Analytics.Event? {
        switch self {
        case .networkUnreachable: return .tokenNoticeNetworkUnreachable
        case .networkNotUpdated: return nil
        case .rentFee: return nil
        case .noAccount: return nil
        case .existentialDepositWarning: return nil
        case .notEnoughFeeForTransaction: return .tokenNoticeNotEnoughFee
        case .bnbBeaconChainRetirement: return nil
        case .hasUnfulfilledRequirements(configuration: .missingHederaTokenAssociation): return nil
        case .hasUnfulfilledRequirements(configuration: .incompleteKaspaTokenTransaction): return .tokenNoticeRevealTransaction
        case .hasUnfulfilledRequirements(configuration: .missingTokenTrustline): return nil
        case .staking: return nil
        case .manaLevel: return nil
        case .maticMigration: return nil
        case .cloreMigration: return nil
        }
    }

    var analyticsParams: [Analytics.ParameterKey: String] {
        switch self {
        case .networkUnreachable(let currencySymbol):
            return [.token: currencySymbol]
        case .notEnoughFeeForTransaction(let configuration):
            return [
                .token: configuration.amountCurrencySymbol,
                .blockchain: configuration.amountCurrencyBlockchainName,
            ]
        case .hasUnfulfilledRequirements(configuration: .incompleteKaspaTokenTransaction(let revealTransaction)):
            return [.token: revealTransaction.currencySymbol, .blockchain: revealTransaction.blockchainName]
        case .rentFee,
             .noAccount,
             .existentialDepositWarning,
             .bnbBeaconChainRetirement,
             .hasUnfulfilledRequirements(configuration: .missingHederaTokenAssociation),
             .hasUnfulfilledRequirements(configuration: .missingTokenTrustline),
             .staking,
             .manaLevel,
             .maticMigration,
             .networkNotUpdated,
             .cloreMigration:
            return [:]
        }
    }

    /// Determine if analytics event should be sent only once and tracked by service
    var isOneShotAnalyticsEvent: Bool { false }
}
