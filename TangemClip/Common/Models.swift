//
//  Models.swift
//  TangemClip
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

class CardViewModel: ObservableObject {
    var cardInfo: CardInfo
    
    init(cardInfo: CardInfo) {
        self.cardInfo = cardInfo
    }
    
    func getCardInfo() {
        
    }
}

class Assembly {
    
    let cardValidator = ValidatedCardsService()
    
    lazy var tangemSdk: TangemSdk = {
       let sdk = TangemSdk()
        sdk.config = Config()
        return sdk
    }()
    lazy var cardsRepository: CardsRepository = {
        let repo = CardsRepository(twinCardFileDecoder: TwinCardTlvFileDecoder(), cardValidator: cardValidator)
        repo.tangemSdk = tangemSdk
        repo.assembly = self
        return repo
    }()
    
    private var modelsStorage = [String : Any]()
    
    var sdkConfig: Config {
        Config()
    }
    
    func getMainViewModel(cid: String) -> MainViewModel {
        guard let model: MainViewModel = get() else {
            let mainModel = MainViewModel(cid: cid, cardsRepository: cardsRepository)
            store(mainModel)
            return mainModel
        }
        
        model.cardNumber = cid
        return model
    }
    
    func getCardModel(from info: CardInfo) -> CardViewModel? {
        guard let model: CardViewModel = get() else {
            let cardViewModel = CardViewModel(cardInfo: info)
            store(cardViewModel)
            return cardViewModel
        }
        
        model.cardInfo = info
        return model
    }
    
    func updateAppClipCard(with cid: String) {
        let mainModel: MainViewModel? = get()
        mainModel?.cardNumber = cid
    }
    
    func updateCardUrl(_ url: String) {
        let mainModel: MainViewModel? = get()
        mainModel?.cardUrl = url
    }
    
    private func store<T>(_ object: T ) {
        let key = String(describing: type(of: T.self))
        store(object, with: key)
    }
    
    private func store<T>(_ object: T, with key: String) {
        //print(key)
        modelsStorage[key] = object
    }
    
    private func get<T>() -> T? {
        let key = String(describing: type(of: T.self))
        return get(key: key)
    }
    
    private func get<T>(key: String) -> T? {
        modelsStorage[key] as? T
    }
}

extension Assembly {
    static var previewAssembly: Assembly = {
        let assembly = Assembly()
        
        // Twin card
        let twinScan = scanResult(for: Card.testTwinCard, assembly: assembly, twinCardInfo: TwinCardInfo(cid: "CB64000000006522", series: .cb64, pairCid: "CB65000000006521", pairPublicKey: nil))
        
        // Bitcoin old test card
        let testCardScan = scanResult(for: Card.testCard, assembly: assembly)
        
        // ETH pigeon card
        let ethCardScan = scanResult(for: Card.testEthCard, assembly: assembly)
        
        // Which card data should be displayed in preview?
        assembly.cardsRepository.lastScanResult = ethCardScan
        return assembly
    }()
    
    private static func scanResult(for card: Card, assembly: Assembly, twinCardInfo: TwinCardInfo? = nil) -> ScanResult {
        let ci = CardInfo(card: card,
                          artworkInfo: nil,
                          twinCardInfo: twinCardInfo)
        let vm = assembly.getCardModel(from: ci)!
        let scanResult = ScanResult.card(model: vm)
        assembly.cardsRepository.cards[card.cardId!] = scanResult
        return scanResult
    }
}

class Analytics {
    enum Event: String {
        case cardIsScanned = "card_is_scanned"
        case transactionIsSent = "transaction_is_sent"
        case readyToScan = "ready_to_scan"
        case displayRateAppWarning = "rate_app_warning_displayed"
        case negativeRateAppFeedback = "negative_rate_app_feedback"
        case positiveRateAppFeedback = "positive_rate_app_feedback"
        case dismissRateAppWarning = "dismiss_rate_app_warning"
    }
    
    static func log(error: Error) {
        print("LOGGING ERRORRRRRR!RR!R!!Rrrr: ", error)
    }
    
    static func logScan(card: Card) {
        print("This is card", card)
    }
    
    static func log(event: Event) {
        print("ALARM!ALRAMRA. This is event", event.rawValue)
    }
}
