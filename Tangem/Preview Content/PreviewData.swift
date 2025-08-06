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
import TangemFoundation

/// Should be wrapped in DEBUG
enum PreviewData {
    static var previewNoteCardOnboardingInput: OnboardingInput {
        OnboardingInput(
            backupService: .init(sdk: .init(), networkService: .init(session: .shared, additionalHeaders: [:])),
            primaryCardId: "",
            cardInitializer: nil,
            pushNotificationsPermissionManager: PushNotificationsPermissionManagerStub(),
            steps: .singleWallet([.createWallet, .success]),
            cardInput: .userWalletModel(PreviewCard.ethEmptyNote.userWalletModel, cardId: ""),
            twinData: nil
        )
    }

    static var previewTwinOnboardingInput: OnboardingInput {
        .init(
            backupService: .init(sdk: .init(), networkService: .init(session: .shared, additionalHeaders: [:])),
            primaryCardId: "",
            cardInitializer: nil,
            pushNotificationsPermissionManager: PushNotificationsPermissionManagerStub(),
            steps: .twins([
                .intro(pairNumber: "0128"),
                .first,
                .second,
                .third,
                .topup,
                .done,
            ]),
            cardInput: .userWalletModel(PreviewCard.twin.userWalletModel, cardId: ""),
            twinData: .init(series: TwinCardSeries.cb61)
        )
    }

    static var previewWalletOnboardingInput: OnboardingInput {
        .init(
            backupService: .init(sdk: .init(), networkService: .init(session: .shared, additionalHeaders: [:])),
            primaryCardId: "",
            cardInitializer: nil,
            pushNotificationsPermissionManager: PushNotificationsPermissionManagerStub(),
            steps: .wallet([.createWallet, .backupIntro, .selectBackupCards, .backupCards, .success]),
            cardInput: .userWalletModel(PreviewCard.tangemWalletEmpty.userWalletModel, cardId: ""),
            twinData: nil
        )
    }
}
