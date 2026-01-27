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
    private typealias AlertInfo = ResetToFactoryUtil.AlertInfo

    private let flow: Flow

    init(flow: Flow) {
        self.flow = flow
    }

    func build(backupCardsCount: Int, cardInteractor: FactorySettingsResetting) -> ResetToFactoryUtil {
        let continueAlertInfo = AlertInfo(
            title: Localization.cardSettingsContinueResetAlertTitle,
            message: Localization.resetCardsDialogNextDeviceDescription,
            primaryButtonTitle: Localization.cardSettingsActionSheetReset,
            secondaryButtonTitle: Localization.commonCancel
        )

        let didFinishMessage: String
        let didFinishPrimaryButtonTitle: String
        switch flow {
        case .reset:
            didFinishMessage = Localization.cardSettingsCompletedResetAlertMessage
            didFinishPrimaryButtonTitle = Localization.commonDone
        case .upgrade:
            didFinishMessage = Localization.cardResetAlertFinishMessage
            didFinishPrimaryButtonTitle = Localization.cardResetAlertFinishOkButton
        }
        let didFinishAlertInfo = AlertInfo(
            title: Localization.cardSettingsCompletedResetAlertTitle,
            message: didFinishMessage,
            primaryButtonTitle: didFinishPrimaryButtonTitle,
            secondaryButtonTitle: Localization.commonCancel
        )

        let incompleteAlertInfo = AlertInfo(
            title: Localization.cardResetAlertIncompleteTitle,
            message: Localization.cardResetAlertIncompleteMessage,
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
        let continueAlertInfo = AlertInfo(
            title: Localization.cardSettingsContinueResetAlertTitle,
            message: Localization.resetCardsDialogNextDeviceDescription,
            primaryButtonTitle: Localization.cardSettingsActionSheetReset,
            secondaryButtonTitle: Localization.commonCancel
        )

        let didFinishAlertInfo = AlertInfo(
            title: Localization.cardSettingsCompletedResetAlertTitle,
            message: Localization.cardSettingsCompletedResetAlertMessage,
            primaryButtonTitle: Localization.commonDone,
            secondaryButtonTitle: Localization.commonCancel
        )

        let incompleteAlertInfo = AlertInfo(
            title: Localization.cardResetAlertIncompleteTitle,
            message: Localization.cardResetAlertIncompleteMessage,
            primaryButtonTitle: Localization.cardSettingsActionSheetReset,
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

// MARK: - Types

extension ResetToFactoryUtilBuilder {
    enum Flow {
        case reset
        case upgrade
    }
}
