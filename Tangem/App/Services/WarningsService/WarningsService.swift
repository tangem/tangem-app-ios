//
//  WarningsService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import Combine
import BlockchainSdk

class WarningsService {
    @Injected(\.rateAppService) var rateAppChecker: RateAppService

    var warningsUpdatePublisher: PassthroughSubject<WarningsLocation, Never> = PassthroughSubject()

    private var mainWarnings: WarningsContainer = .init() {
        didSet {
            warningsUpdatePublisher.send(.main)
        }
    }

    private var sendWarnings: WarningsContainer = .init() {
        didSet {
            warningsUpdatePublisher.send(.send)
        }
    }

    private var currentCardId: String = ""

    init() {}

    deinit {
        print("WarningsService deinit")
    }

    private func warningsForMain(for cardInfo: CardInfo) -> WarningsContainer {
        let container = WarningsContainer()

        addTestnetCardWarningIfNeeded(in: container, for: cardInfo)
        addDevCardWarningIfNeeded(in: container, for: cardInfo)
        addLowRemainingSignaturesWarningIfNeeded(in: container, for: cardInfo.card)
        addOldCardWarning(in: container, for: cardInfo.card)
        addOldDeviceOldCardWarningIfNeeded(in: container, for: cardInfo.card)
        addDemoWarningIfNeeded(in: container, for: cardInfo)
        addAuthFailedIfNeeded(in: container, for: cardInfo)


        if rateAppChecker.shouldShowRateAppWarning {
            Analytics.log(event: .displayRateAppWarning)
            container.add(WarningEvent.rateApp.warning)
        }

        return container
    }

    private func warningsForSend(for cardInfo: CardInfo) -> WarningsContainer {
        let container = WarningsContainer()

        addTestnetCardWarningIfNeeded(in: container, for: cardInfo)
        addOldDeviceOldCardWarningIfNeeded(in: container, for: cardInfo.card)

        return container
    }

    private func addAuthFailedIfNeeded(in container: WarningsContainer, for cardInfo: CardInfo) {
        if cardInfo.card.firmwareVersion.type != .sdk &&
            cardInfo.card.attestation.status == .failed {
            container.add(WarningEvent.failedToValidateCard.warning)
        }
    }

    private func addDevCardWarningIfNeeded(in container: WarningsContainer, for cardInfo: CardInfo) {
//        guard cardInfo.card.firmwareVersion.type == .sdk, !cardInfo.isTestnet, !cardInfo.card.isDemoCard else { //[REDACTED_TODO_COMMENT]
//            return
//        }

        container.add(WarningsList.devCard)
    }

    private func addOldCardWarning(in container: WarningsContainer, for card: Card) {
        // if card.canSign { return } [REDACTED_TODO_COMMENT]

        container.add(WarningsList.oldCard)
    }

    private func addOldDeviceOldCardWarningIfNeeded(in container: WarningsContainer, for card: Card) {
        guard  card.firmwareVersion.doubleValue < 2.28 else { // old cards
            return
        }

        guard NFCUtils.isPoorNfcQualityDevice else { // old phone
            return
        }

        container.add(WarningsList.oldDeviceOldCard)
    }

    private func addLowRemainingSignaturesWarningIfNeeded(in container: WarningsContainer, for card: Card) {
        if let remainingSignatures = card.wallets.first?.remainingSignatures,
           remainingSignatures <= 10 {
            container.add(WarningsList.lowSignatures(count: remainingSignatures))
        }
    }

    private func addTestnetCardWarningIfNeeded(in container: WarningsContainer, for cardInfo: CardInfo) {
//        guard cardInfo.isTestnet, !cardInfo.card.isDemoCard else {
//            return
//        }
        // [REDACTED_TODO_COMMENT]
        container.add(WarningEvent.testnetCard.warning)
    }

    private func addDemoWarningIfNeeded(in container: WarningsContainer, for cardInfo: CardInfo) {
//        if cardInfo.card.isDemoCard { //[REDACTED_TODO_COMMENT]
//            container.add(WarningsList.demoCard)
//        }
    }
}

extension WarningsService: AppWarningsProviding {
    func setupWarnings(for cardInfo: CardInfo) {
        currentCardId = cardInfo.card.cardId

        mainWarnings = warningsForMain(for: cardInfo)
        sendWarnings = warningsForSend(for: cardInfo)
    }

    func didSign(with card: Card) {
        guard currentCardId == card.cardId else { return }

        addLowRemainingSignaturesWarningIfNeeded(in: mainWarnings, for: card)
    }

    func warnings(for location: WarningsLocation) -> WarningsContainer {
        switch location {
        case .main:
            return mainWarnings
        case .send:
            return sendWarnings
        }
    }

    func appendWarning(for event: WarningEvent) {
        let warning = event.warning
        if event.locationsToDisplay.contains(.main) {
            mainWarnings.add(warning)
        }
        if event.locationsToDisplay.contains(.send) {
            sendWarnings.add(warning)
        }
    }

    func hideWarning(_ warning: AppWarning) {
        mainWarnings.remove(warning)
        sendWarnings.remove(warning)
    }

    func hideWarning(for event: WarningEvent) {
        mainWarnings.removeWarning(for: event)
        sendWarnings.removeWarning(for: event)
    }
}
