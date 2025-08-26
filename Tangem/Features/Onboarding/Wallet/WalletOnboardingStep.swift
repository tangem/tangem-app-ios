//
//  WalletOnboardingStep.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets

enum WalletOnboardingStep: Equatable {
    case pushNotifications
    case createWallet
    case scanPrimaryCard
    case backupIntro
    case selectBackupCards
    case backupCards
    case saveUserWallet

    // Wallet 2.0
    case createWalletSelector
    case seedPhraseIntro
    case seedPhraseGeneration
    case seedPhraseUserValidation
    case seedPhraseImport
    case mobileUpgrade

    case addTokens

    case success

    var isInitialBackupStep: Bool {
        switch self {
        case .backupIntro, .selectBackupCards:
            return true
        default:
            return false
        }
    }

    var isCreateWalletStep: Bool {
        switch self {
        case .createWallet,
             .createWalletSelector,
             .seedPhraseUserValidation,
             .seedPhraseImport:
            return true
        default:
            return false
        }
    }

    var navbarTitle: String {
        switch self {
        case .pushNotifications:
            return Localization.onboardingTitleNotifications
        case .createWallet, .backupIntro:
            return Localization.onboardingGettingStarted
        case .scanPrimaryCard, .selectBackupCards:
            return Localization.onboardingNavbarTitleCreatingBackup
        case .backupCards:
            return Localization.onboardingButtonFinalizeBackup
        case .saveUserWallet:
            return Localization.onboardingNavbarSaveWallet
        case .success:
            return Localization.commonDone
        case .createWalletSelector:
            return Localization.walletTitle
        case .seedPhraseIntro, .seedPhraseGeneration, .seedPhraseUserValidation:
            return Localization.onboardingCreateWalletButtonCreateWallet
        case .seedPhraseImport:
            return Localization.onboardingSeedIntroButtonImport
        case .addTokens:
            return Localization.onboardingAddTokens
        case .mobileUpgrade:
            return "Tangem"
        }
    }

    static var resumeBackupSteps: [WalletOnboardingStep] {
        [.backupCards, .success]
    }

    func cardBackgroundFrame(containerSize: CGSize) -> CGSize {
        switch self {
        case .success, .backupCards, .addTokens:
            return .zero
        default:
            let cardFrame = WalletOnboardingCardLayout.origin.frame(for: .createWallet, containerSize: containerSize)
            let diameter = cardFrame.height * 1.242
            return .init(width: diameter, height: diameter)
        }
    }

    func backgroundOffset(in container: CGSize) -> CGSize {
        let cardOffset = WalletOnboardingCardLayout.origin.offset(at: .createWallet, in: container)
        return cardOffset
    }

    var balanceStackOpacity: Double { 0 }
}

extension WalletOnboardingStep: OnboardingMessagesProvider, SuccessStep {
    var title: String? {
        switch self {
        case .createWallet: return Localization.onboardingCreateWalletButtonCreateWallet
        case .scanPrimaryCard: return Localization.onboardingTitleScanOriginCard
        case .backupIntro: return nil
        case .selectBackupCards: return Localization.onboardingTitleNoBackupCards
        case .backupCards: return ""
        case .success: return successTitle
        case .createWalletSelector:
            return Localization.onboardingCreateWalletOptionsTitle
        case .seedPhraseIntro, .seedPhraseGeneration, .seedPhraseImport, .seedPhraseUserValidation, .addTokens, .saveUserWallet, .pushNotifications:
            return nil
        case .mobileUpgrade: return Localization.commonTangemWallet
        }
    }

    var subtitle: String? {
        switch self {
        case .createWallet: return Localization.onboardingCreateWalletBody
        case .scanPrimaryCard: return Localization.onboardingSubtitleScanPrimary
        case .backupIntro: return nil
        case .selectBackupCards: return Localization.onboardingSubtitleNoBackupCards
        case .backupCards: return ""
        case .success: return Localization.onboardingSubtitleSuccessTangemWalletOnboarding
        case .createWalletSelector:
            return Localization.onboardingCreateWalletOptionsMessage
        case .seedPhraseIntro, .seedPhraseGeneration, .seedPhraseImport, .seedPhraseUserValidation, .addTokens, .saveUserWallet, .pushNotifications:
            return nil
        case .mobileUpgrade: return "You’re about to upgrade your wallet to Tangem Wallet. This will keep your assets safe with cold storage."
        }
    }

    var messagesOffset: CGSize {
        switch self {
        case .success: return CGSize(width: 0, height: -2)
        default: return .zero
        }
    }
}

extension WalletOnboardingStep: OnboardingButtonsInfoProvider {
    var mainButtonTitle: String {
        switch self {
        case .createWalletSelector: return Localization.onboardingCreateWalletButtonCreateWallet
        case .backupIntro: return Localization.onboardingButtonBackupNow
        case .selectBackupCards: return Localization.onboardingButtonAddBackupCard
        case .saveUserWallet: return BiometricAuthorizationUtils.allowButtonTitle
        case .success: return Localization.onboardingButtonContinueWallet
        case .seedPhraseIntro: return Localization.onboardingSeedIntroButtonGenerate
        default: return ""
        }
    }

    var mainButtonIcon: ImageType? {
        switch self {
        case .createWallet, .createWalletSelector, .selectBackupCards, .backupCards, .mobileUpgrade:
            return Assets.tangemIcon
        default:
            return nil
        }
    }

    var supplementButtonTitle: String {
        switch self {
        case .createWallet: return Localization.onboardingCreateWalletButtonCreateWallet
        case .backupIntro: return Localization.onboardingButtonSkipBackup
        case .selectBackupCards: return Localization.onboardingButtonFinalizeBackup
        case .createWalletSelector: return Localization.onboardingCreateWalletOptionsButtonOptions
        case .seedPhraseIntro: return Localization.onboardingSeedIntroButtonImport
        case .success: return Localization.onboardingButtonContinueWallet
        case .scanPrimaryCard: return Localization.onboardingButtonScanOriginCard
        case .mobileUpgrade: return "Start upgrade"
        default: return ""
        }
    }

    var supplementButtonIcon: ImageType? {
        switch self {
        case .backupCards, .scanPrimaryCard, .mobileUpgrade:
            return Assets.tangemIcon
        default:
            return nil
        }
    }

    var isContainSupplementButton: Bool {
        true
    }

    var checkmarkText: String? {
        return nil
    }

    var infoText: String? {
        switch self {
        case .saveUserWallet:
            return Localization.saveUserWalletAgreementNotice
        default:
            return nil
        }
    }
}

extension WalletOnboardingStep: OnboardingProgressStepIndicatable {
    var requiresConfetti: Bool {
        switch self {
        case .success:
            return true
        default:
            return false
        }
    }

    var successCircleOpacity: Double {
        self == .success ? 1.0 : 0.0
    }

    var successCircleState: OnboardingCircleButton.State {
        switch self {
        case .success: return .doneCheckmark
        default: return .blank
        }
    }
}
