//
//  TwinConfigBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

class TwinConfigBuilder: UserWalletConfigBuilder {
    private let card: Card
    private let twinData: TwinCardInfo

    private var onboardingSteps: [TwinsOnboardingStep] {
        var steps = [TwinsOnboardingStep]()

        if !AppSettings.shared.isTwinCardOnboardingWasDisplayed { // show intro only once
            AppSettings.shared.isTwinCardOnboardingWasDisplayed = true
            let twinPairCid = AppTwinCardIdFormatter.format(cid: "", cardNumber: twinData.series.pair.number)
            steps.append(.intro(pairNumber: "\(twinPairCid)"))
        }

        if card.wallets.isEmpty { // twin without created wallet. Start onboarding
            steps.append(contentsOf: TwinsOnboardingStep.twinningProcessSteps)
            steps.append(contentsOf: TwinsOnboardingStep.topupSteps)
            return steps
        } else { // twin with created wallet
            if twinData.pairPublicKey == nil { // is not twinned
                steps.append(contentsOf: TwinsOnboardingStep.twinningProcessSteps)
                steps.append(contentsOf: TwinsOnboardingStep.topupSteps)
                return steps
            } else { // is twinned
                if AppSettings.shared.cardsStartedActivation.contains(card.cardId) { // card is in onboarding process, go to topup
                    steps.append(contentsOf: TwinsOnboardingStep.topupSteps)
                    return steps
                } else { // unknown twin, ready to use, go to main
                    return steps
                }
            }
        }
    }

    init(card: Card, twinData: TwinCardInfo) {
        self.card = card
        self.twinData = twinData
    }

    func buildConfig() -> UserWalletConfig {
        var features = baseFeatures(for: card)

        features.insert(.sendingToPayIDAllowed)
        features.insert(.exchangingAllowed)
        features.insert(.signingSupported)
        features.insert(.activation)

        if twinData.pairPublicKey != nil {
            features.insert(.settingPasscodeAllowed)
        }

        let config = UserWalletConfig(cardIdFormatted: AppTwinCardIdFormatter.format(cid: card.cardId,
                                                                                     cardNumber: twinData.series.number),
                                      emailConfig: .default,
                                      touURL: nil,
                                      cardSetLabel: .init(format: "card_label_number_format".localized, twinData.series.number, 2),
                                      cardIdDisplayFormat: .lastLunh(4),
                                      features: features,
                                      defaultBlockchain: .bitcoin(testnet: false),
                                      defaultToken: nil,
                                      onboardingSteps: .twins(onboardingSteps),
                                      backupSteps: nil,
                                      defaultDisabledFeatureAlert: nil)
        return config
    }
}
