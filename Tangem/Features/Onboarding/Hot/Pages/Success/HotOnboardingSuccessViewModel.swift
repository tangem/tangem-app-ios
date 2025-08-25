//
//  HotOnboardingSuccessViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemAssets
import TangemLocalization

final class HotOnboardingSuccessViewModel {
    lazy var infoItem = makeInfoItem()
    lazy var actionItem = makeActionItem()

    private let type: SuccessType
    private weak var delegate: HotOnboardingSuccessDelegate?

    init(type: SuccessType, delegate: HotOnboardingSuccessDelegate) {
        self.type = type
        self.delegate = delegate
    }
}

// MARK: - Internal methods

extension HotOnboardingSuccessViewModel {
    func onAppear() {
        if type == .walletReady {
            delegate?.fireConfetti()
        }
    }
}

// MARK: - Private methods

private extension HotOnboardingSuccessViewModel {
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
        case .walletImported, .seedPhaseBackupContinue:
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
            action: { [weak delegate] in
                delegate?.success()
            }
        )
    }
}

// MARK: - Types

extension HotOnboardingSuccessViewModel {
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
