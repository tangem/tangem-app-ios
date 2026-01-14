//
//  MobileOnboardingSuccessViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemAssets
import TangemLocalization

final class MobileOnboardingSuccessViewModel {
    lazy var infoItem = makeInfoItem()
    lazy var actionItem = makeActionItem()

    private var isAppeared = false

    private let type: SuccessType
    private let onAppear: () -> Void
    private let onComplete: () -> Void

    init(
        type: SuccessType,
        onAppear: @escaping () -> Void,
        onComplete: @escaping () -> Void
    ) {
        self.type = type
        self.onAppear = onAppear
        self.onComplete = onComplete
    }
}

// MARK: - Internal methods

extension MobileOnboardingSuccessViewModel {
    func onWillAppear() {
        guard !isAppeared else { return }
        isAppeared = true
        onAppear()
    }
}

// MARK: - Private methods

private extension MobileOnboardingSuccessViewModel {
    func makeInfoItem() -> InfoItem {
        let title = switch type {
        case .walletImported:
            Localization.walletImportSuccessTitle
        case .seedPhaseBackupContinue, .seedPhaseBackupFinish:
            Localization.backupCompleteTitle
        case .walletReady:
            Localization.onboardingDoneHeader
        }

        let description = switch type {
        case .walletImported:
            Localization.walletImportSuccessDescription
        case .seedPhaseBackupContinue:
            Localization.backupCompleteDescription
        case .seedPhaseBackupFinish:
            Localization.backupCompleteSeedDescription
        case .walletReady:
            Localization.onboardingDoneWallet
        }

        return InfoItem(
            icon: Assets.Onboarding.successCheckmark,
            title: title,
            description: description
        )
    }

    func makeActionItem() -> ActionItem {
        let title = switch type {
        case .walletImported, .seedPhaseBackupContinue:
            Localization.commonContinue
        case .walletReady, .seedPhaseBackupFinish:
            Localization.commonFinish
        }

        return ActionItem(
            title: title,
            action: { [weak self] in
                self?.completeAction()
            }
        )
    }

    func completeAction() {
        onComplete()
    }
}

// MARK: - Types

extension MobileOnboardingSuccessViewModel {
    enum SuccessType {
        case seedPhaseBackupContinue
        case seedPhaseBackupFinish
        case walletImported
        case walletReady
    }

    struct InfoItem {
        let icon: ImageType
        let title: String
        let description: String
    }

    struct ActionItem {
        let title: String
        let action: () -> Void
    }
}
