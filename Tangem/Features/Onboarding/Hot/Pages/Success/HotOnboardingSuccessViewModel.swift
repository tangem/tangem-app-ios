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
    lazy var continueItem = makeContinueItem()

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
        if type == .done {
            delegate?.fireConfetti()
        }
    }
}

// MARK: - Private methods

private extension HotOnboardingSuccessViewModel {
    func makeInfoItem() -> InfoItem {
        let title = switch type {
        case .import:
            Localization.walletImportSuccessTitle
        case .backup:
            Localization.backupCompleteTitle
        case .done:
            Localization.onboardingDoneHeader
        }

        let description = switch type {
        case .import, .backup:
            Localization.backupCompleteDescription
        case .done:
            Localization.onboardingDoneWallet
        }

        return InfoItem(
            icon: Assets.Onboarding.successCheckmark,
            title: title,
            description: description
        )
    }

    func makeContinueItem() -> ContinueItem {
        let title = switch type {
        case .import, .backup:
            Localization.commonContinue
        case .done:
            Localization.commonFinish
        }

        return ContinueItem(
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
        case `import`
        case backup
        case done
    }

    struct InfoItem {
        let icon: ImageType
        let title: String
        let description: String
    }

    struct ContinueItem {
        let title: String
        let action: () -> Void
    }
}
