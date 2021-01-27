//
//  TwinsWalletCreationService.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk

class TwinsWalletCreationService {
    
    enum CreationStep {
        case first, second, third, done
    }
    
    static let twinFileName = "TwinPublicKey"
    
    private let scanMessageKey = "twins_scan_twin_with_number"
    
    private let tangemSdk: TangemSdk
    private let twinFileEncoder: TwinCardFileEncoder
    private let cardsRepository: CardsRepository
    
    private var firstTwinCid: String = ""
    private var secondTwinCid: String = ""
    private var twinInfo: TwinCardInfo?
    
    private var firstTwinPublicKey: Data?
    private var secondTwinPublicKey: Data?
    
    private(set) var step = CurrentValueSubject<CreationStep, Never>(.first)
    private(set) var occuredError = PassthroughSubject<Error, Never>()
    private(set) var isServiceBusy = CurrentValueSubject<Bool, Never>(false)
    
    /// Determines is user start twin wallet creation from Twin card with first number
    var isStartedFromFirstNumber: Bool {
        guard let twin = twinInfo else { return true }
        return twin.series?.number ?? 1 == 1
    }
    
    var stepCardNumber: Int {
        guard
            let twin = twinInfo,
            let series = twin.series
        else { return 1 }
        switch step.value {
        case .first, .third, .done:
            return series.number
        case .second:
            return series.pair.number
        }
    }
    
    init(tangemSdk: TangemSdk, twinFileEncoder: TwinCardFileEncoder, cardsRepository: CardsRepository) {
        self.tangemSdk = tangemSdk
        self.twinFileEncoder = twinFileEncoder
        self.cardsRepository = cardsRepository
    }
    
    func executeCurrentStep() {
        isServiceBusy.send(true)
        switch step.value {
        case .first:
            createWalletOnFirstCard()
        case .second:
            createWalletOnSecondCard()
        case .third:
            writeSecondPublicKeyToFirst()
        case .done:
            step.send(.done)
        }
    }
    
    func setupTwins(for twin: TwinCardInfo) {
        if twin.cid == firstTwinCid, twin.pairCid == secondTwinCid { return }
        
        twinInfo = twin
        firstTwinCid = twin.cid
        secondTwinCid = twin.pairCid ?? ""
    }
    
    func resetSteps() {
        step = CurrentValueSubject<CreationStep, Never>(.first)
        isServiceBusy.send(false)
    }
    
    private func createWalletOnFirstCard() {
        let task = TwinsCreateWalletTask(targetCid: firstTwinCid, fileToWrite: nil)
        tangemSdk.startSession(with: task, cardId: firstTwinCid, initialMessage: initialMessage(for: firstTwinCid)) { (result) in
            switch result {
            case .success(let response):
                self.cardsRepository.lastScanResult.cardModel?.update(withCreateWaletResponse: response)
                self.firstTwinPublicKey = response.walletPublicKey
                self.step.send(.second)
            case .failure(let error):
                self.occuredError.send(error)
            }
            self.isServiceBusy.send(false)
        }
    }
    
    private func createWalletOnSecondCard() {
        guard let firstTwinKey = firstTwinPublicKey else {
            step.send(.first)
            occuredError.send(TangemSdkError.missingIssuerPublicKey)
            return
        }
        
        //		switch twinFileToWrite(publicKey: firstTwinKey) {
        //		case .success(let file):
        let task = TwinsCreateWalletTask(targetCid: secondTwinCid, fileToWrite: firstTwinKey)
        tangemSdk.startSession(with: task, cardId: secondTwinCid, initialMessage: initialMessage(for: secondTwinCid)) { (result) in
            switch result {
            case .success(let response):
                self.secondTwinPublicKey = response.walletPublicKey
                self.step.send(.third)
            case .failure(let error):
                self.occuredError.send(error)
            }
            self.isServiceBusy.send(false)
        }
        //		case .failure(let error):
        //			occuredError.send(error)
        //		}
        
    }
    
    private func writeSecondPublicKeyToFirst() {
        guard let secondTwinKey = secondTwinPublicKey else {
            step.send(.second)
            occuredError.send(TangemSdkError.missingIssuerPublicKey)
            return
        }
        
        //		switch twinFileToWrite(publicKey: secondTwinKey) {
        //		case .success(let file):
        let task = TwinsFinalizeWalletCreationTask(fileToWrite: secondTwinKey)
        tangemSdk.startSession(with: task, cardId: firstTwinCid, initialMessage: initialMessage(for: firstTwinCid)) { [weak self] (result) in
            guard let self = self else { return }
            
            switch result {
            case .success(let response):
                self.cardsRepository.lastScanResult.cardModel?.update(with: response.getCardInfo())
                self.step.send(.done)
            case .failure(let error):
                self.occuredError.send(error)
            }
            self.isServiceBusy.send(false)
        }
        //		case .failure(let error):
        //			occuredError.send(error)
        //		}
    }
    
    private func twinFileToWrite(publicKey: Data) -> Result<Data, Error> {
        do {
            let data = try twinFileEncoder.encode(TwinCardFile(publicKey: publicKey, fileTypeName: TwinsWalletCreationService.twinFileName))
            return .success(data)
        } catch {
            print("Failed to encode twin file:", error)
            return .failure(error)
        }
    }
    
    private func initialMessage(for cardId: String) -> Message {
        Message(header: String(format: scanMessageKey.localized, TapTwinCardIdFormatter.format(cid: cardId, cardNumber: stepCardNumber)))
    }
    
}
