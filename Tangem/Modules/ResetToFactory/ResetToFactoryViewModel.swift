//
//  ResetToFactoryViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI


class ResetToFactoryViewModel: ObservableObject {
    @Published var actionSheet: ActionSheetBinder?
    @Published var alert: AlertBinder?

    var message: String {
        if cardModel.isMultiWallet, cardModel.hasBackupCards {
            return "Factory Reset will completely delete the wallet from the selected card. You will not be able to restore the current wallet or use the card to recover the access code."
        }

        return "Factory Reset will completely delete the wallet from the selected card. You will not be able to restore the current wallet."
    }

    private let cardModel: CardViewModel
    private unowned let coordinator: ResetToFactoryViewRoutable

    init(cardModel: CardViewModel, coordinator: ResetToFactoryViewRoutable) {
        self.cardModel = cardModel
        self.coordinator = coordinator
    }

    func mainButtonDidTap() {
        showConfirmationAlert()
    }
}

private extension ResetToFactoryViewModel {
    func showConfirmationAlert() {
        let sheet = ActionSheet(
            title: Text(L10n.cardSettingsActionActionSheetTitle),
            buttons: [
                .destructive(Text(L10n.cardSettingsActionActionSheetReset)) { [weak self] in
                    self?.resetCardToFactory()
                },
                .cancel(Text(L10n.commonCancel)),
            ])

        self.actionSheet = ActionSheetBinder(sheet: sheet)
    }

    func resetCardToFactory() {
        cardModel.resetToFactory { [weak self] result in
            switch result {
            case .success:
                self?.coordinator.didResetCard()
            case let .failure(error):
                if !error.isUserCancelled {
                    self?.alert = error.alertBinder
                }
            }
        }
    }
}
