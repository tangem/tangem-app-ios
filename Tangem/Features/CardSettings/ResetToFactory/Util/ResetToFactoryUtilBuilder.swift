//
//  ResetToFactoryUtilBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

struct ResetToFactoryUtilBuilder {
    func build(backupCardsCount: Int, cardInteractor: FactorySettingsResetting) -> ResetToFactoryUtil {
        let continueAlertInfo = ResetToFactoryUtil.AlertInfo(
            title: Localization.cardSettingsContinueResetAlertTitle,
            message: Localization.cardSettingsContinueResetAlertMessage,
            primaryButtonTitle: Localization.cardSettingsActionSheetReset,
            secondaryButtonTitle: Localization.commonCancel
        )

        let didFinishAlertInfo = ResetToFactoryUtil.AlertInfo(
            title: Localization.cardSettingsCompletedResetAlertTitle,
            message: Localization.cardSettingsCompletedResetAlertMessage,
            primaryButtonTitle: Localization.commonOk,
            secondaryButtonTitle: Localization.commonCancel
        )

        let incompleteAlertInfo = ResetToFactoryUtil.AlertInfo(
            title: Localization.cardSettingsInterruptedResetAlertTitle,
            message: Localization.cardSettingsInterruptedResetAlertMessage,
            primaryButtonTitle: Localization.cardSettingsActionSheetReset,
            secondaryButtonTitle: Localization.commonCancel
        )

        let input = ResetToFactoryUtil.Input(
            totalCardsCount: backupCardsCount + 1,
            interactorMode: .single(cardInteractor),
            continueAlertInfo: continueAlertInfo,
            didFinishAlertInfo: didFinishAlertInfo,
            incompleteAlertInfo: incompleteAlertInfo
        )

        return ResetToFactoryUtil(input: input)
    }

    func build(cardInteractors: [FactorySettingsResetting]) -> ResetToFactoryUtil {
        let continueAlertInfo = ResetToFactoryUtil.AlertInfo(
            title: Localization.cardResetAlertContinueTitle,
            message: Localization.cardResetAlertContinueMessage,
            primaryButtonTitle: Localization.commonReset,
            secondaryButtonTitle: Localization.commonCancel
        )

        let didFinishAlertInfo = ResetToFactoryUtil.AlertInfo(
            title: Localization.cardResetAlertFinishTitle,
            message: Localization.cardResetAlertFinishMessage,
            primaryButtonTitle: Localization.cardResetAlertFinishOkButton,
            secondaryButtonTitle: Localization.commonCancel
        )

        let incompleteAlertInfo = ResetToFactoryUtil.AlertInfo(
            title: Localization.cardResetAlertIncompleteTitle,
            message: Localization.cardResetAlertIncompleteMessage,
            primaryButtonTitle: Localization.commonReset,
            secondaryButtonTitle: Localization.commonCancel
        )

        let input = ResetToFactoryUtil.Input(
            totalCardsCount: cardInteractors.count,
            interactorMode: .multiple(cardInteractors),
            continueAlertInfo: continueAlertInfo,
            didFinishAlertInfo: didFinishAlertInfo,
            incompleteAlertInfo: incompleteAlertInfo
        )

        return ResetToFactoryUtil(input: input)
    }
}
