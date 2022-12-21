//
//  WalletOnboardingStep.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

enum WalletOnboardingStep: Equatable {
    case welcome
    case createWallet
    case scanPrimaryCard
    case backupIntro
    case selectBackupCards
    case backupCards
    case saveUserWallet

    // visa only
    case enterPin
    case registerWallet
    case kycStart
    case kycRetry
    case kycProgress
    case kycWaiting
    case claim
    case successClaim

    case success

    var navbarTitle: String {
        switch self {
        case .welcome: return ""
        case .createWallet, .backupIntro: return L10n.onboardingGettingStarted
        case .scanPrimaryCard, .selectBackupCards: return L10n.onboardingNavbarTitleCreatingBackup
        case .backupCards: return L10n.onboardingButtonFinalizeBackup
        case .saveUserWallet: return L10n.onboardingNavbarSaveWallet
        case .success: return L10n.commonDone
        case .enterPin:
            return L10n.onboardingNavbarPin
        case .registerWallet:
            return L10n.onboardingNavbarRegisterWallet
        case .kycStart, .kycProgress, .kycWaiting, .kycRetry:
            return L10n.onboardingNavbarKycProgress
        case .claim, .successClaim:
            return L10n.onboardingGettingStarted
        }
    }

    static var resumeBackupSteps: [WalletOnboardingStep] {
        [.backupCards, .success]
    }

    func cardBackgroundFrame(containerSize: CGSize) -> CGSize {
        switch self {
        case .welcome, .success, .backupCards:
            return .zero
        case .claim, .successClaim:
            return defaultBackgroundFrameSize(in: containerSize)
        default:
            let cardFrame = WalletOnboardingCardLayout.origin.frame(for: self, containerSize: containerSize)
            let diameter = cardFrame.height * 1.242
            return .init(width: diameter, height: diameter)
        }
    }

    func cardBackgroundCornerRadius(containerSize: CGSize) -> CGFloat {
        switch self {
        case .welcome, .success, .backupCards: return 0
        case .claim, .successClaim: return 8
        default: return cardBackgroundFrame(containerSize: containerSize).height / 2
        }
    }

    func backgroundOffset(in container: CGSize) -> CGSize {
        switch self {
        case .claim, .successClaim:
            return defaultBackgroundOffset(in: container)
        default:
            let cardOffset = WalletOnboardingCardLayout.origin.offset(at: .createWallet, in: container)
            return cardOffset
        }
    }

    var balanceStackOpacity: Double {
        switch self {
        case .claim, .successClaim: return 1
        default: return 0
        }
    }
}

extension WalletOnboardingStep: OnboardingMessagesProvider, SuccessStep {
    var title: String? {
        switch self {
        case .welcome: return WelcomeStep.welcome.title
        case .createWallet: return L10n.onboardingCreateWalletButtonCreateWallet
        case .scanPrimaryCard: return L10n.onboardingTitleScanOriginCard
        case .backupIntro: return L10n.onboardingTitleBackupCard
        case .selectBackupCards: return L10n.onboardingTitleNoBackupCards
        case .backupCards, .kycProgress: return ""
        case .saveUserWallet: return nil
        case .success, .successClaim: return successTitle
        case .registerWallet:
            return L10n.onboardingTitleRegisterWallet
        case .kycStart:
            return L10n.onboardingTitleKycStart
        case .kycRetry:
            return L10n.onboardingTitleKycRetry
        case .kycWaiting:
            return L10n.onboardingTitleKycWaiting
        case .enterPin:
            return L10n.onboardingTitlePin
        case .claim:
            return ""
        }
    }

    var subtitle: String? {
        switch self {
        case .welcome: return WelcomeStep.welcome.subtitle
        case .createWallet: return L10n.onboardingCreateWalletBody
        case .scanPrimaryCard: return L10n.onboardingSubtitleScanPrimary
        case .backupIntro: return L10n.onboardingSubtitleBackupCard
        case .selectBackupCards: return L10n.onboardingSubtitleNoBackupCards
        case .backupCards, .kycProgress: return ""
        case .saveUserWallet: return nil
        case .success: return L10n.onboardingSubtitleSuccessBackup
        case .registerWallet:
            return L10n.onboardingSubtitleRegisterWallet
        case .kycStart:
            return L10n.onboardingSubtitleKycStart
        case .kycRetry:
            return L10n.onboardingSubtitleKycRetry
        case .kycWaiting:
            return L10n.onboardingSubtitleKycWaiting
        case .enterPin:
            return L10n.onboardingSubtitlePin
        case .claim:
            return L10n.onboardingSubtitleClaim
        case .successClaim:
            return L10n.onboardingSubtitleSuccessClaim
        }
    }

    var messagesOffset: CGSize {
        switch self {
        case .success, .claim, .successClaim: return CGSize(width: 0, height: -2)
        default: return .zero
        }
    }
}

extension WalletOnboardingStep: OnboardingButtonsInfoProvider {
    var mainButtonTitle: String {
        switch self {
        case .welcome: return WelcomeStep.welcome.mainButtonTitle
        case .createWallet: return L10n.walletButtonCreateWallet
        case .scanPrimaryCard: return L10n.onboardingButtonScanOriginCard
        case .backupIntro: return L10n.onboardingButtonBackupNow
        case .selectBackupCards: return L10n.onboardingButtonAddBackupCard
        case .backupCards, .kycProgress: return ""
        case .saveUserWallet: return BiometricAuthorizationUtils.allowButtonLocalizationKey
        case .success: return L10n.onboardingButtonContinueWallet
        case .kycWaiting: return L10n.onboardingSupplementButtonKycWaiting
        default: return ""
        }
    }

    var supplementButtonTitle: String {
        switch self {
        case .welcome: return WelcomeStep.welcome.supplementButtonTitle
        case .createWallet: return L10n.onboardingButtonWhatDoesItMean
        case .backupIntro: return L10n.onboardingButtonSkipBackup
        case .selectBackupCards: return L10n.onboardingButtonFinalizeBackup
        case .kycWaiting: return  L10n.onboardingButtonKycWaiting
        case .enterPin: return L10n.onboardingButtonPin
        case .registerWallet:  return L10n.onboardingButtonRegisterWallet
        case .kycStart, .kycRetry:  return L10n.onboardingButtonKycStart
        case .claim: return L10n.onboardingButtonClaim
        case .successClaim: return L10n.onboardingButtonContinueWallet
        default: return ""
        }

    }

    var isSupplementButtonVisible: Bool {
        switch self {
        case .scanPrimaryCard, .backupCards, .success, .createWallet: return false
        default: return true
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
            return L10n.saveUserWalletAgreementNotice
        default:
            return nil
        }
    }
}

extension WalletOnboardingStep: OnboardingInitialStepInfo {
    static var initialStep: WalletOnboardingStep {
        .welcome
    }
}

extension WalletOnboardingStep: OnboardingProgressStepIndicatable {
    var isOnboardingFinished: Bool {
        self == .success ||  self == .successClaim
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

extension WalletOnboardingStep: OnboardingTopupBalanceLayoutCalculator { }
