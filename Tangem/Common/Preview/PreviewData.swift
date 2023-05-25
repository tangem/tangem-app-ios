//
//  PreviewData.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

struct PreviewData {
    static var previewNoteCardOnboardingInput: OnboardingInput {
        OnboardingInput(
            backupService: .init(sdk: .init()),
            cardInitializer: nil,
            steps: .singleWallet([.createWallet, .success]),
            cardInput: .cardModel(PreviewCard.ethEmptyNote.cardModel),
            twinData: nil
        )
    }

    static var previewTwinOnboardingInput: OnboardingInput {
        .init(
            backupService: .init(sdk: .init()),
            cardInitializer: nil,
            steps: .twins([
                .intro(pairNumber: "0128"),
                .first,
                .second,
                .third,
                .topup,
                .done,
            ]),
            cardInput: .cardModel(PreviewCard.twin.cardModel),
            twinData: .init(series: TwinCardSeries.cb61)
        )
    }

    static var previewWalletOnboardingInput: OnboardingInput {
        .init(
            backupService: .init(sdk: .init()),
            cardInitializer: nil,
            steps: .wallet([.createWallet, .backupIntro, .selectBackupCards, .backupCards, .success]),
            cardInput: .cardModel(PreviewCard.tangemWalletEmpty.cardModel),
            twinData: nil
        )
    }
}
