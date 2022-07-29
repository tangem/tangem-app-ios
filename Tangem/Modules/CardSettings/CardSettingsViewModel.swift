//
//  CardSettingsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine

class CardSettingsViewModel: ObservableObject {
    // MARK: ViewState

    @Published var hasSingleSecurityMode: Bool = false
    @Published var isChangeAccessCodeVisible: Bool = false
    @Published var securityModeTitle: String?
    @Published var alert: AlertBinder?

    var cardId: String {
        let cardId = cardModel.cardInfo.card.cardId
        if cardModel.isTwinCard {
            return AppTwinCardIdFormatter.format(
                cid: cardId,
                cardNumber: cardModel.cardInfo.twinCardInfo?.series.number
            )
        }

        return AppCardIdFormatter(cid: cardId).formatted()
    }

    var cardIssuer: String {
        cardModel.cardInfo.card.issuer.name
    }

    var cardSignedHashes: String? {
        guard cardModel.hasWallet, !cardModel.isTwinCard else {
            return nil
        }

        return "\(cardModel.cardInfo.card.walletSignedHashes)"
    }

    // MARK: Dependecies

    private unowned let coordinator: CardSettingsRoutable
    private let cardModel: CardViewModel

    // MARK: Properties

    private var bag: Set<AnyCancellable> = []
    private var shouldShowAlertOnDisableSaveAccessCodes: Bool = true

    init(
        cardModel: CardViewModel,
        coordinator: CardSettingsRoutable
    ) {
        self.cardModel = cardModel
        self.coordinator = coordinator

        securityModeTitle = cardModel.currentSecurityOption.title
        hasSingleSecurityMode = cardModel.availableSecurityOptions.count <= 1
        isChangeAccessCodeVisible = cardModel.currentSecurityOption == .accessCode

        bind()
    }
}

// MARK: - Private

private extension CardSettingsViewModel {
    func bind() {
        cardModel.$currentSecurityOption
            .map { $0.title }
            .weakAssign(to: \.securityModeTitle, on: self)
            .store(in: &bag)
    }
}

// MARK: - Navigation

extension SecurityPrivacyViewModel {
    func openChangeAccessCodeWarningView() {
        coordinator.openChangeAccessCodeWarningView { [weak self] completion in
            guard let self = self else { return }

            self.cardModel.changeSecurityOption(.accessCode, completion: completion)
        }
    }

    func openSecurityMode() {
        coordinator.openSecurityMode(cardModel: cardModel)
    }
}
