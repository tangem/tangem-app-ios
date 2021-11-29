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

protocol WarningsConfigurator: AnyObject {
    func setupWarnings(for cardInfo: CardInfo)
}

protocol WarningAppendor: AnyObject {
    func appendWarning(for event: WarningEvent)
}

protocol WarningsManager: WarningAppendor {
    var warningsUpdatePublisher: PassthroughSubject<WarningsLocation, Never> { get }
    func warnings(for location: WarningsLocation) -> WarningsContainer
    func hideWarning(_ warning: AppWarning)
    func hideWarning(for event: WarningEvent)
}

class WarningsService {
    
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
    
    private let remoteWarningProvider: RemoteWarningProvider
    private let rateAppChecker: RateAppChecker
    
    init(remoteWarningProvider: RemoteWarningProvider, rateAppChecker: RateAppChecker) {
        self.remoteWarningProvider = remoteWarningProvider
        self.rateAppChecker = rateAppChecker
    }
    
    deinit {
        print("WarningsService deinit")
    }
    
    private func warningsForMain(for cardInfo: CardInfo) -> WarningsContainer {
        let container = WarningsContainer()
        
        addTestnetCardWarningIfNeeded(in: container, for: cardInfo)
        addDevCardWarningIfNeeded(in: container, for: cardInfo.card)
        addLowRemainingSignaturesWarningIfNeeded(in: container, for: cardInfo.card)
        addOldCardWarning(in: container, for: cardInfo.card)
        addOldDeviceOldCardWarningIfNeeded(in: container, for: cardInfo.card)
        
        addAuthFailedIfNeeded(in: container, for: cardInfo)
        
        if rateAppChecker.shouldShowRateAppWarning {
            Analytics.log(event: .displayRateAppWarning)
            container.add(WarningEvent.rateApp.warning)
        }
        
        let remoteWarnings = self.remoteWarnings(for: cardInfo, location: .main)
        container.add(remoteWarnings)
        
        return container
    }
    
    private func warningsForSend(for cardInfo: CardInfo) -> WarningsContainer {
        let container = WarningsContainer()
        
        addTestnetCardWarningIfNeeded(in: container, for: cardInfo)
        addOldDeviceOldCardWarningIfNeeded(in: container, for: cardInfo.card)
        
        let remoteWarnings = self.remoteWarnings(for: cardInfo, location: .send)
        container.add(remoteWarnings)
        
        return container
    }
    
    private func remoteWarnings(for cardInfo: CardInfo, location: WarningsLocation) -> [AppWarning] {
        let remoteWarnings = remoteWarningProvider.warnings
        let mainRemoteWarnings = remoteWarnings.filter { $0.location.contains { $0 == location } }

        let cardRemoteWarnings = mainRemoteWarnings.filter {
            $0.blockchains == nil ||
                $0.blockchains?.contains { $0.lowercased() == (cardInfo.walletData?.blockchain ?? "").lowercased() } ?? false
        }
        return cardRemoteWarnings
    }
    
    private func addAuthFailedIfNeeded(in container: WarningsContainer, for cardInfo: CardInfo) {
        if cardInfo.card.firmwareVersion.type != .sdk &&
            cardInfo.card.attestation.status == .failed {
            container.add(WarningEvent.failedToValidateCard.warning)
        }
    }
    
    private func addDevCardWarningIfNeeded(in container: WarningsContainer, for card: Card) {
        guard card.firmwareVersion.type == .sdk else {
            return
        }
        
        container.add(WarningsList.devCard)
    }
    
    private func addOldCardWarning(in container: WarningsContainer, for card: Card) {
        if card.canSign { return }
        
        container.add(WarningsList.oldCard)
    }
    
    private func addOldDeviceOldCardWarningIfNeeded(in container: WarningsContainer, for card: Card) {
        guard  card.firmwareVersion.doubleValue < 2.28 else { //old cards
            return
        }
        
        guard NFCUtils.isPoorNfcQualityDevice else { //old phone
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
        guard cardInfo.isTestnet else {
            return
        }
        
        container.add(WarningEvent.testnetCard.warning)
    }
    
}

extension WarningsService: WarningsManager {
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

extension WarningsService: WarningsConfigurator {
    func setupWarnings(for cardInfo: CardInfo) {
        mainWarnings = warningsForMain(for: cardInfo)
        sendWarnings = warningsForSend(for: cardInfo)
    }
}
