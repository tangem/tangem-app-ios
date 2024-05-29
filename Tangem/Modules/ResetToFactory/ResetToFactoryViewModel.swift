//
//  ResetToFactoryViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

class ResetToFactoryViewModel: ObservableObject {
    @Published var warnings: [Warning] = []
    @Published var actionSheet: ActionSheetBinder?
    @Published var alert: AlertBinder?

    var actionButtonIsEnabled: Bool {
        warnings.allConforms(\.isAccepted)
    }

    var message: String {
        if hasLinkedCards {
            return Localization.resetCardWithBackupToFactoryMessage
        } else {
            return Localization.resetCardWithoutBackupToFactoryMessage
        }
    }

    private let hasLinkedCards: Bool
    private let resetHelper: ResetToFactoryService
    private let cardInteractor: FactorySettingsResetting
    private weak var coordinator: ResetToFactoryViewRoutable?

    init(input: ResetToFactoryViewModel.Input, coordinator: ResetToFactoryViewRoutable) {
        cardInteractor = input.cardInteractor
        hasLinkedCards = input.linkedCardsCount > 0
        resetHelper = ResetToFactoryService(
            userWalletId: input.userWalletId,
            totalCardsCount: input.linkedCardsCount + 1
        )
        self.coordinator = coordinator

        setupView()
    }

    deinit {
        AppLog.shared.debug("ResetToFactoryViewModel deinit")
    }

    func didTapMainButton() {
        showConfirmationAlert()
    }

    func toggleWarning(warningType: WarningType) {
        guard let index = warnings.firstIndex(where: { $0.type == warningType }) else {
            return
        }

        warnings[index].isAccepted.toggle()
    }
}

private extension ResetToFactoryViewModel {
    func setupView() {
        warnings.append(Warning(isAccepted: false, type: .accessToCard))

        if hasLinkedCards {
            warnings.append(Warning(isAccepted: false, type: .accessCodeRecovery))
        }
    }

    func showConfirmationAlert() {
        let sheet = ActionSheet(
            title: Text(Localization.cardSettingsActionSheetTitle),
            buttons: [
                .destructive(Text(Localization.cardSettingsActionSheetReset)) { [weak self] in
                    self?.resetCardToFactory()
                },
                .cancel(Text(Localization.commonCancel)),
            ]
        )

        actionSheet = ActionSheetBinder(sheet: sheet)
    }

    func resetCardToFactory() {
        let header = makeHeader(from: resetHelper.cardNumberToReset)
        cardInteractor.resetCard(headerMessage: header) { [weak self] result in
            guard let self else { return }

            switch result {
            case .success:
                resetHelper.cardDidReset()

                if resetHelper.hasCardsToReset {
                    alert = ResetToFactoryAlertBuilder.makeContinueResetAlert(continueAction: resetCardToFactory, cancelAction: resetDidCancel)
                } else {
                    alert = ResetToFactoryAlertBuilder.makeResetDidFinishAlert(continueAction: resetDidFinish)
                }

            case .failure(let error):
                if resetHelper.resettedCardsCount == 0 {
                    if !error.isUserCancelled {
                        alert = error.alertBinder
                    }
                } else {
                    alert = ResetToFactoryAlertBuilder.makeResetIncompleteAlert(continueAction: resetCardToFactory, cancelAction: resetDidFinish)
                }

                if !error.isUserCancelled {
                    AppLog.shared.error(error, params: [.action: .purgeWallet])
                }
            }
        }
    }

    func makeHeader(from cardNumber: Int?) -> String? {
        guard let cardNumber, cardNumber > 1 else {
            return nil
        }

        return "Tap the card #\(cardNumber) of the wallet to reset"
    }

    func resetDidCancel() {
        // Add a delay between successive alerts
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.alert = ResetToFactoryAlertBuilder.makeResetIncompleteAlert(continueAction: self.resetCardToFactory, cancelAction: self.resetDidFinish)
        }
    }

    func resetDidFinish() {
        resetHelper.resetDidDinish()
        coordinator?.dismiss()
    }
}

extension ResetToFactoryViewModel {
    struct Warning: Identifiable, Hashable {
        var id: Int { hashValue }

        var isAccepted: Bool
        let type: WarningType
    }

    enum WarningType: String, CaseIterable, Hashable {
        case accessToCard
        case accessCodeRecovery

        var title: String {
            switch self {
            case .accessToCard:
                return Localization.resetCardToFactoryCondition1
            case .accessCodeRecovery:
                return Localization.resetCardToFactoryCondition2
            }
        }
    }
}

private enum ResetToFactoryAlertBuilder {
    static func makeContinueResetAlert(continueAction: @escaping () -> Void, cancelAction: @escaping () -> Void) -> AlertBinder {
        AlertBuilder.makeAlert(
            title: "Card reset",
            message: "Do you want to reset next card of this wallet?",
            primaryButton: .default(Text(Localization.commonContinue), action: continueAction),
            secondaryButton: .destructive(Text(Localization.commonCancel), action: cancelAction)
        )
    }

    static func makeResetDidFinishAlert(continueAction: @escaping () -> Void) -> AlertBinder {
        AlertBuilder.makeAlert(
            title: "Reseting complete",
            message: "All cards in the selected wallet have been reset to factory settings, you can create a new wallet now.",
            primaryButton: .default(Text(Localization.commonOk), action: continueAction)
        )
    }

    static func makeResetIncompleteAlert(continueAction: @escaping () -> Void, cancelAction: @escaping () -> Void) -> AlertBinder {
        AlertBuilder.makeAlert(
            title: "Reseting incomplete",
            message: "You didn't reset all your cards. We recommend completing the reset to create a new wallet. A card containing an active wallet cannot participate in the process of creating a new one.",
            primaryButton: .default(Text(Localization.commonContinue), action: continueAction),
            secondaryButton: .destructive(Text(Localization.commonCancel), action: cancelAction)
        )
    }
}
