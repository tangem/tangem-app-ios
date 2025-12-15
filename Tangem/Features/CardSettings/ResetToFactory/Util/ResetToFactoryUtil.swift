//
//  ResetToFactoryUtil.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import TangemLocalization
import struct TangemUIUtils.AlertBinder

final class ResetToFactoryUtil {
    var alertPublisher: AnyPublisher<AlertBinder, Never> {
        alertSubject.eraseToAnyPublisher()
    }

    private let alertSubject = PassthroughSubject<AlertBinder, Never>()
    private var hasCardsToReset: Bool {
        input.totalCardsCount != resettedCardsCount
    }

    private var cardNumberToReset: Int {
        min(resettedCardsCount + 1, input.totalCardsCount)
    }

    private var resettedCardsCount: Int = 0

    private let input: Input

    init(input: Input) {
        self.input = input
    }
}

// MARK: - Internal methods

extension ResetToFactoryUtil {
    func resetToFactory(onDidFinish: @escaping () -> Void) {
        let header = makeHeader(from: cardNumberToReset)
        guard let cardInteractor = input.interactorMode.getInteractor(for: resettedCardsCount) else {
            onDidFinish()
            return
        }

        cardInteractor.resetCard(headerMessage: header) { [weak self] result in
            guard let self else { return }

            switch result {
            case .success(let didReset):
                switch input.interactorMode {
                case .single:
                    if didReset {
                        resettedCardsCount += 1
                    }
                case .multiple:
                    resettedCardsCount += 1
                }

                if hasCardsToReset {
                    send(alert: makeContinueResetAlert(onDidFinish: onDidFinish))
                } else {
                    send(alert: makeResetDidFinishAlert(onDidFinish: onDidFinish))
                }

            case .failure(let error):
                if resettedCardsCount == 0 {
                    if !error.isUserCancelled {
                        send(alert: error.alertBinder)
                    }
                } else {
                    send(alert: makeResetIncompleteAlert(onDidFinish: onDidFinish))
                }

                if !error.isUserCancelled {
                    AppLogger.error(error: error)
                    Analytics.error(error: error, params: [.action: .purgeWallet])
                }
            }
        }
    }
}

// MARK: - Private methods

private extension ResetToFactoryUtil {
    func resetDidCancel(onDidFinish: @escaping () -> Void) {
        // Add a delay between successive alerts
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self else { return }
            send(alert: makeResetIncompleteAlert(onDidFinish: onDidFinish))
        }
    }

    func resetDidFinish(handler: () -> Void) {
        logAnalytics()
        handler()
    }

    func makeHeader(from cardNumber: Int) -> String? {
        guard cardNumber > 1 else {
            return nil
        }

        return Localization.initialMessageResetBackupCardHeader(cardNumber)
    }

    func send(alert: AlertBinder) {
        alertSubject.send(alert)
    }

    func logAnalytics() {
        let params = [Analytics.ParameterKey.cardsCount: "\(resettedCardsCount)"]

        if hasCardsToReset {
            Analytics.log(event: .factoryResetCancelled, params: params)
        } else {
            Analytics.log(event: .factoryResetFinished, params: params)
        }
    }
}

// MARK: - AlertBinders

private extension ResetToFactoryUtil {
    func makeContinueResetAlert(onDidFinish: @escaping () -> Void) -> AlertBinder {
        let info = input.continueAlertInfo
        return AlertBuilder.makeAlert(
            title: info.title,
            message: info.message,
            primaryButton: .default(
                Text(info.primaryButtonTitle),
                action: { [weak self] in
                    self?.resetToFactory(onDidFinish: onDidFinish)
                }
            ),
            secondaryButton: .destructive(
                Text(info.secondaryButtonTitle),
                action: { [weak self] in
                    self?.resetDidCancel(onDidFinish: onDidFinish)
                }
            )
        )
    }

    func makeResetDidFinishAlert(onDidFinish: @escaping () -> Void) -> AlertBinder {
        let info = input.didFinishAlertInfo
        return AlertBuilder.makeAlertWithDefaultPrimaryButton(
            title: info.title,
            message: info.message,
            buttonText: info.primaryButtonTitle,
            buttonAction: { [weak self] in
                self?.resetDidFinish(handler: onDidFinish)
            }
        )
    }

    func makeResetIncompleteAlert(onDidFinish: @escaping () -> Void) -> AlertBinder {
        let info = input.incompleteAlertInfo
        return AlertBuilder.makeAlert(
            title: info.title,
            message: info.message,
            primaryButton: .default(
                Text(info.primaryButtonTitle),
                action: { [weak self] in
                    self?.resetToFactory(onDidFinish: onDidFinish)
                }
            ),
            secondaryButton: .destructive(
                Text(info.secondaryButtonTitle),
                action: { [weak self] in
                    self?.resetDidFinish(handler: onDidFinish)
                }
            )
        )
    }
}

// MARK: - Types

extension ResetToFactoryUtil {
    struct Input {
        let totalCardsCount: Int
        let interactorMode: InteractorMode
        let continueAlertInfo: AlertInfo
        let didFinishAlertInfo: AlertInfo
        let incompleteAlertInfo: AlertInfo
    }

    struct AlertInfo {
        let title: String
        let message: String
        let primaryButtonTitle: String
        let secondaryButtonTitle: String
    }

    enum InteractorMode {
        case single(FactorySettingsResetting)
        case multiple([FactorySettingsResetting])

        func getInteractor(for cardIndex: Int) -> FactorySettingsResetting? {
            switch self {
            case .single(let interactor):
                return interactor
            case .multiple(let interactors):
                return interactors[safe: cardIndex]
            }
        }
    }
}
