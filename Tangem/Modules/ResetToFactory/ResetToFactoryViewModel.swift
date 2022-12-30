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
        if cardModel.hasBackupCards {
            return Localization.resetCardWithBackupToFactoryMessage
        } else {
            return Localization.resetCardWithoutBackupToFactoryMessage
        }
    }

    private let cardModel: CardViewModel
    private unowned let coordinator: ResetToFactoryViewRoutable

    init(cardModel: CardViewModel, coordinator: ResetToFactoryViewRoutable) {
        self.cardModel = cardModel
        self.coordinator = coordinator
    }

    func didTapMainButton() {
        showConfirmationAlert()
    }
}

private extension ResetToFactoryViewModel {
    func showConfirmationAlert() {
        let sheet = ActionSheet(
            title: Text(Localization.cardSettingsActionSheetTitle),
            buttons: [
                .destructive(Text(Localization.cardSettingsActionSheetReset)) { [weak self] in
                    self?.resetCardToFactory()
                },
                .cancel(Text(Localization.commonCancel)),
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
