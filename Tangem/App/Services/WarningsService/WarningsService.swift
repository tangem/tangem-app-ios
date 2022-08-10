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

    var warningsUpdatePublisher: CurrentValueSubject<Void, Never> = .init(())

    private var mainWarnings: WarningsContainer = .init()
    private var sendWarnings: WarningsContainer = .init()

    private var currentCardId: String = ""

    init() {}

    deinit {
        print("WarningsService deinit")
    }
}

extension WarningsService: AppWarningsProviding {
    func setupWarnings(for config: UserWalletConfig) {

        // currentCardId = cardInfo.card.cardId

        let main = WarningsContainer()
        let send = WarningsContainer()

        for warningEvent in config.warningEvents  {
            if warningEvent.locationsToDisplay.contains(WarningsLocation.main) {
                main.add(warningEvent.warning)
            }

            if warningEvent.locationsToDisplay.contains(WarningsLocation.send) {
                send.add(warningEvent.warning)
            }
        }

        if rateAppChecker.shouldShowRateAppWarning {
            Analytics.log(event: .displayRateAppWarning)
            main.add(WarningEvent.rateApp.warning)
        }

        mainWarnings = main
        sendWarnings = send
        warningsUpdatePublisher.send(())
    }


    func didSign(with card: Card) {
        guard currentCardId == card.cardId else { return }

        //addLowRemainingSignaturesWarningIfNeeded(in: mainWarnings, for: card)
        warningsUpdatePublisher.send(())
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
