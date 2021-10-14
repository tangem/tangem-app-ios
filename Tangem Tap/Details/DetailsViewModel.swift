//
//  DetailsViewModel.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import TangemSdk
import BlockchainSdk

class DetailsViewModel: ViewModel, ObservableObject {
    weak var assembly: Assembly!
    weak var navigation: NavigationCoordinator!
    weak var cardsRepository: CardsRepository!
    weak var onboardingStepsSetupService: OnboardingStepsSetupService!
    
    weak var ratesService: CoinMarketCapService! {
        didSet {
            ratesService
                .$selectedCurrencyCodePublished
                .receive(on: RunLoop.main)
                .sink { [weak self] _ in
                    self?.objectWillChange.send()
                }
                .store(in: &bag)
        }
    }
    
    
    @Published var cardModel: CardViewModel! {
        didSet {
            cardModel.objectWillChange
                .receive(on: RunLoop.main)
                .sink { [weak self] in
                    self?.objectWillChange.send()
                }
                .store(in: &bag)
        }
    }
    @Published var isTwinRecreationModel: Bool = false
    @Published var error: AlertBinder?
    
    var dataCollector: DetailsFeedbackDataCollector!
    
    var hasWallet: Bool {
        cardModel.hasWallet
    }
    
    var shouldShowWC: Bool {
        cardModel.cardInfo.card.wallets.contains(where: { $0.curve == .secp256k1 })
            && (cardModel.wallets?.contains(where: { $0.blockchain == .ethereum(testnet: false) || $0.blockchain == .ethereum(testnet: true) }) ?? false)
    }
    
    var isTwinCard: Bool {
        cardModel.isTwinCard
    }
    
    var cardTouURL: URL? {
        guard cardModel.isStart2CoinCard else { //is this card is S2C
            return nil
        }
        
        let baseurl = "https://app.tangem.com/tou/"
        let regionCode = self.regionCode(for: cardModel.cardInfo.card.cardId) ?? "fr"
        let languageCode = Locale.current.languageCode ?? "fr"
        let filename = self.filename(languageCode: languageCode, regionCode: regionCode)
        let url = URL(string: baseurl + filename)
        return url
    }
    
    private func filename(languageCode: String, regionCode: String) -> String {
        switch (languageCode,regionCode) {
        case ("fr", "ch"):
            return "Start2Coin-fr-ch-tangem.pdf"
        case ("de", "ch"):
            return "Start2Coin-de-ch-tangem.pdf"
        case ("en", "ch"):
            return "Start2Coin-en-ch-tangem.pdf"
        case ("it", "ch"):
            return "Start2Coin-it-ch-tangem.pdf"
        case ("fr", "fr"):
            return "Start2Coin-fr-fr-atangem.pdf"
        case ("de", "at"):
            return "Start2Coin-de-at-tangem.pdf"
        case (_, "fr"):
            return "Start2Coin-fr-fr-atangem.pdf"
        case (_, "ch"):
            return "Start2Coin-en-ch-tangem.pdf"
        case (_, "at"):
            return "Start2Coin-de-at-tangem.pdf"
        default:
            return "Start2Coin-fr-fr-atangem.pdf"
        }
    }
    
    private func regionCode(for cid: String) -> String? {
        let cidPrefix = cid[cid.index(cid.startIndex, offsetBy: 1)]
        switch cidPrefix {
        case "0":
            return "fr"
        case "1":
            return "ch"
        case "2":
            return "at"
        default:
            return nil
        }
    }
    
    var cardCid: String {
        let cardId = cardModel.cardInfo.card.cardId
        return isTwinCard ?
            TapTwinCardIdFormatter.format(cid: cardId, cardNumber: cardModel.cardInfo.twinCardInfo?.series.number) :
            TapCardIdFormatter(cid: cardId).formatted()
    }
    
    private var bag = Set<AnyCancellable>()
    
    func checkPin(_ completion: @escaping () -> Void) {
        cardModel.checkPin { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                completion()
            case .failure(let error):
                Analytics.logCardSdkError(error.toTangemSdkError(), for: .readPinSettings, card: self.cardModel.cardInfo.card)
            }
        }
    }
    
    func prepareTwinOnboarding() {
        onboardingStepsSetupService.twinRecreationSteps(for: cardModel.cardInfo)
            .sink { completion in
            switch completion {
            case .failure(let error):
                Analytics.log(error: error)
                print("Failed to load image for new card")
                self.error = error.alertBinder
            case .finished:
                break
            }
        } receiveValue: { [weak self] steps in
            guard let self = self else { return }
            
            let input = OnboardingInput(steps: steps,
                                        cardModel: self.cardModel,
                                        cardImage: nil,
                                        cardsPosition: nil,
                                        welcomeStep: nil,
                                        currentStepIndex: 0,
                                        successCallback: { [weak self] in
                                            self?.navigation.detailsToTwinsRecreateWarning = false
                                        })
            self.assembly.makeCardOnboardingViewModel(with: input)
            self.navigation.detailsToTwinsRecreateWarning = true
        }
        .store(in: &bag)
    }
}
