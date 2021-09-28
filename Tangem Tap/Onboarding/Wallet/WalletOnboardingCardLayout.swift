//
//  WalletOnboardingCardLayout.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

enum WalletOnboardingCardLayout {
    case origin, firstBackup, secondBackup
    
    var zIndex: Double {
        switch self {
        case .origin: return 100
        case .firstBackup: return 99
        case .secondBackup: return 98
        }
    }
    
    var cardFanStackIndex: Int {
        switch self {
        case .origin: return 0
        case .firstBackup: return 1
        case .secondBackup: return 2
        }
    }
    
    func animSettings(at step: WalletOnboardingStep, in container: CGSize, fanStackCalculator: FanStackCalculator, animated: Bool) -> AnimatedViewSettings {
        switch (self, step) {
        case (.origin, .welcome):
            return WelcomeCardLayout.main.cardSettings(at: .welcome, in: container, animated: animated)
        case (.firstBackup, .welcome):
            return WelcomeCardLayout.supplementary.cardSettings(at: .welcome, in: container, animated: animated)
        case (.secondBackup, .welcome):
            var settings = WelcomeCardLayout.supplementary.cardSettings(at: .welcome, in: container, animated: animated)
            settings.targetSettings.opacity = 0
            return settings
        case (_, .selectBackupCards):
            return .init(targetSettings: fanStackCalculator.settingsForCard(at: cardFanStackIndex),
                         intermediateSettings: nil)
        case (_, .success):
            return .zero
        case (.origin, _), (.firstBackup, _), (.secondBackup, _):
            return .init(targetSettings: CardAnimSettings(frame: frame(for: step, containerSize: container),
                                                          offset: offset(at: step, in: container),
                                                          scale: scale(at: step, in: container),
                                                          opacity: opacity(at: step, in: container),
                                                          zIndex: zIndex,
                                                          rotationAngle: rotation(at: step, in: container)),
                         intermediateSettings: nil)
        }
    }
    
    func offset(at step: WalletOnboardingStep, in container: CGSize) -> CGSize {
//        switch (self, step) {
//        case (_, .createWallet):
            return .init(width: 0, height: container.height * 0.089)
//        default:
//            return .zero
//        }
    }
    
    func scale(at step: WalletOnboardingStep, in container: CGSize) -> CGFloat {
        1
    }
    
    func opacity(at step: WalletOnboardingStep, in container: CGSize) -> Double {
        switch (self, step) {
        case (.secondBackup, .createWallet), (.secondBackup, .welcome), (_, .success): return 0
        default:
            return 1
        }
    }
    
    func rotation(at step: WalletOnboardingStep, in container: CGSize) -> Angle {
        .zero
    }
}

extension WalletOnboardingCardLayout: OnboardingCardFrameCalculator {
    typealias Step = WalletOnboardingStep
    
    var cardHeightWidthRatio: CGFloat {
        0.629
    }
    
    func cardHeightToContainerHeightRatio(for step: WalletOnboardingStep) -> CGFloat {
        switch step {
        case .createWallet, .scanOriginCard, .backupIntro:
            return 0.453
        case .selectBackupCards:
            return 0.318
        default:
            return 0.5
        }
    }
    
    func cardFrameMinHorizontalPadding(at step: WalletOnboardingStep) -> CGFloat {
        switch (self, step) {
        case (_, .createWallet), (_, .scanOriginCard), (_, .backupIntro): return 60
        case (_, .selectBackupCards): return 143
        default: return 0
        }
    }
}
