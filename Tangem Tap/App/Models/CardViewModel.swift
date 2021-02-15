//
//  CardViewModel.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk
import Combine
import Alamofire
import SwiftUI

class CardViewModel: Identifiable, ObservableObject {
    //MARK: Services
    weak var featuresService: AppFeaturesService!
    var payIDService: PayIDService? = nil
    weak var tangemSdk: TangemSdk!
    weak var assembly: Assembly!
    
    @Published var state: State = .created
    @Published var payId: PayIdStatus = .notSupported
    @Published private(set) var currentSecOption: SecurityManagementOption = .longTap
    
    var canSetAccessCode: Bool {
       return (cardInfo.card.settingsMask?.contains(.allowSetPIN1) ?? false ) &&
			featuresService.canSetAccessCode
    }
    
    var canSetPasscode: Bool {
        return !(cardInfo.card.settingsMask?.contains(.prohibitDefaultPIN1) ?? false) &&
			featuresService.canSetPasscode
    }
    
    var canSetLongTap: Bool {
        return cardInfo.card.settingsMask?.contains(.allowSetPIN2) ?? false
    }
    
    var canSign: Bool {
        cardInfo.card.canSign
    }
    
    var hasWallet: Bool {
        if case .loaded = state { return true }
        return false
    }
    
    var purgeWalletProhibitedDescription: String? {
        if isTwinCard {
            return nil
        }
        
        guard hasWallet else { return nil }
        
        if cardInfo.card.settingsMask?.contains(.prohibitPurgeWallet) ?? false {
            return TangemSdkError.purgeWalletProhibited.localizedDescription
        }
        
        if !canPurgeWallet {
            return "details_notification_erase_wallet_not_possible".localized
        }
        
        return nil
    }
    
    var canPurgeWallet: Bool {
        if let status = cardInfo.card.status, status == .empty {
            return false
        }
        
        if cardInfo.card.settingsMask?.contains(.prohibitPurgeWallet) ?? false {
            return false
        }
        
        if case let .loaded(walletModel) = state {
            if case .noAccount = walletModel.state  {
                return true
            }
            
            if case .loading = walletModel.state  {
                return false
            }
            
            if case .failed = walletModel.state   {
                return false
            }
            
            if !walletModel.wallet.isEmpty || walletModel.wallet.hasPendingTx {
                return false
            }
            
            return true
        } else {
            return false
        }
    }
	
	var isTwinCard: Bool {
		cardInfo.card.isTwinCard
	}
    
    var canCreateTwinCard: Bool {
        guard
            isTwinCard,
            let twinInfo = cardInfo.twinCardInfo,
            twinInfo.series != nil
        else { return false }
        
        if case .empty = state {
            
            if cardInfo.card.status == .empty {
                return true
            }
            
            if twinInfo.pairPublicKey != nil {
                return false
            }
            
            return true
        } else {
            return false
        }
    }
	
	var canRecreateTwinCard: Bool {
		guard isTwinCard && cardInfo.twinCardInfo?.series != nil && featuresService.canCreateTwin else { return false }
		
		if case .empty = state {
			return false
		}
        
        if cardInfo.card.settingsMask?.contains(.prohibitPurgeWallet) ?? false {
            return false
        }
        
        if case let .loaded(walletModel) = state {
            if !walletModel.wallet.isEmpty || walletModel.wallet.hasPendingTx {
                return false
            }
            
            switch walletModel.state {
            case .failed, .loading: return false
            case .noAccount: return true
            default:
                break
            }
            
        }
		
		return true
	}
    
    var canManageSecurity: Bool {
        cardInfo.card.isPin1Default != nil &&
            cardInfo.card.isPin2Default != nil
    }
    
    var canTopup: Bool { featuresService.canTopup }
    
    public private(set) var cardInfo: CardInfo
    
    private var bag =  Set<AnyCancellable>()
    
    init(cardInfo: CardInfo) {
        self.cardInfo = cardInfo
        
        updateCurrentSecOption()
    }
    
    func loadPayIDInfo () {
        guard featuresService.canReceiveToPayId else {
            return
        }
        
        payIDService?
            .loadPayIDInfo(for: cardInfo.card)
            .subscribe(on: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                    switch completion {
                    case .failure(let error):
                        print("payid load failed")
                        Analytics.log(error: error)
                        print(error.localizedDescription)
                    case .finished:
                        break
                    }}){ [unowned self] status in
                print("payid loaded")
                self.payId = status
            }
            .store(in: &bag)
    }

    func createPayID(_ payIDString: String, completion: @escaping (Result<Void, Error>) -> Void) { //todo: move to payidservice
        guard featuresService.canReceiveToPayId,
              !payIDString.isEmpty,
              let cid = cardInfo.card.cardId,
              let payIDService = self.payIDService,
              let cardPublicKey = cardInfo.card.cardPublicKey,
              let address = state.wallet?.address  else {
            completion(.failure(PayIdError.unknown))
            return
        }

        let fullPayIdString = payIDString + "$payid.tangem.com"
        payIDService.createPayId(cid: cid, key: cardPublicKey,
                                 payId: fullPayIdString,
                                 address: address) { [weak self] result in
            switch result {
            case .success:
                UIPasteboard.general.string = fullPayIdString
                self?.payId = .created(payId: fullPayIdString)
                completion(.success(()))
            case .failure(let error):
                Analytics.log(error: error)
                completion(.failure(error))
            }
        }

    }
    
    func update() {
        guard state.canUpdate else {
            return
        }
        
        loadPayIDInfo()
        state.walletModel?.update()
    }
    
    func onSign(_ signResponse: SignResponse) {
        cardInfo.card.walletSignedHashes = signResponse.walletSignedHashes
    }
    
    func changeSecOption(_ option: SecurityManagementOption, completion: @escaping (Result<Void, Error>) -> Void) {
        switch option {
        case .accessCode:
            tangemSdk.startSession(with: SetPinCommand(pinType: .pin1, isExclusive: true),
                                   cardId: cardInfo.card.cardId!,
                                   initialMessage: Message(header: nil, body: "initial_message_change_access_code_body".localized)) {[weak self] result in
                switch result {
                case .success:
                    self?.cardInfo.card.isPin1Default = false
                    self?.cardInfo.card.isPin2Default = true
                    self?.updateCurrentSecOption()
                    completion(.success(()))
                case .failure(let error):
                    Analytics.log(error: error)
                    completion(.failure(error))
                }
            }
        case .longTap:
            tangemSdk.startSession(with: SetPinCommand(), cardId: cardInfo.card.cardId!) {[weak self] result in
                switch result {
                case .success:
                    self?.cardInfo.card.isPin1Default = true
                    self?.cardInfo.card.isPin2Default = true
                    self?.updateCurrentSecOption()
                    completion(.success(()))
                case .failure(let error):
                    Analytics.log(error: error)
                    completion(.failure(error))
                }
            }
        case .passCode:
            tangemSdk.startSession(with: SetPinCommand(pinType: .pin2, isExclusive: true),
                                   cardId: cardInfo.card.cardId!,
                                   initialMessage: Message(header: nil, body: "initial_message_change_passcode_body".localized)) {[weak self] result in
                switch result {
                case .success:
                    self?.cardInfo.card.isPin2Default = false
                    self?.cardInfo.card.isPin1Default = true
                    self?.updateCurrentSecOption()
                    completion(.success(()))
                case .failure(let error):
                    Analytics.log(error: error)
                    completion(.failure(error))
                }
            }
        }
    }
    
    func createWallet(_ completion: @escaping (Result<Void, Error>) -> Void) {
        tangemSdk.createWallet(cardId: cardInfo.card.cardId!,
                               initialMessage: Message(header: nil,
                                                       body: "initial_message_create_wallet_body".localized)) {[unowned self] result in
            switch result {
            case .success(let response):
				self.update(withCreateWaletResponse: response)
                completion(.success(()))
            case .failure(let error):
                Analytics.log(error: error)
                completion(.failure(error))
            }
        }
    }
    
    func purgeWallet(completion: @escaping (Result<Void, Error>) -> Void) {
        tangemSdk.purgeWallet(cardId: cardInfo.card.cardId!,
                              initialMessage: Message(header: nil,
                                                      body: "initial_message_purge_wallet_body".localized)) {[unowned self] result in
            switch result {
            case .success(let response):
                var card = self.cardInfo.card.updating(with: response)
                card.walletSignedHashes = nil
                self.cardInfo.card = card
                self.updateState()
                completion(.success(()))
            case .failure(let error):
                Analytics.log(error: error)
                completion(.failure(error))
            }
        }
    }
	
	func update(withCreateWaletResponse response: CreateWalletResponse) {
		cardInfo.card = cardInfo.card.updating(with: response)
		if cardInfo.card.isTwinCard {
			cardInfo.twinCardInfo?.pairPublicKey = nil
		}
		updateState()
	}
    
    func update(with cardInfo: CardInfo) {
        self.cardInfo = cardInfo
        updateState()
    }
    
    func updateState() {
        if let wm = self.assembly.makeWalletModel(from: cardInfo) {
            self.state = .loaded(walletModel: wm)
        } else {
            self.state = .empty
        }
        
        update()
    }
    
    private func updateCurrentSecOption() {
        if !(cardInfo.card.isPin1Default ?? true) {
            self.currentSecOption = .accessCode
        } else if !(cardInfo.card.isPin2Default ?? true) {
            self.currentSecOption = .passCode
        }
        else {
            self.currentSecOption = .longTap
        }
    }
}

extension CardViewModel {
    enum State {
        case created
        case empty
        case loaded(walletModel: WalletModel)
        
        var walletModel: WalletModel? {
            switch self {
            case .loaded(let model):
                return model
            default:
                return nil
            }
        }
        
        var wallet: Wallet? {
            switch self {
            case .loaded(let model):
                return model.wallet
            default:
                return nil
            }
        }
        
        var canUpdate: Bool {
            switch self {
            case .loaded:
                return true
            default:
                return false
            }
        }
    }
}


extension CardViewModel {
    static var previewCardViewModel: CardViewModel {
        let assembly = Assembly.previewAssembly
        return assembly.cardsRepository.cards[Card.testCard.cardId!]!.cardModel!
    }
    
    static var previewCardViewModelNoWallet: CardViewModel {
        let assembly = Assembly.previewAssembly
        return assembly.cardsRepository.cards[Card.testCardNoWallet.cardId!]!.cardModel!
    }
	
	static var previewTwinCardViewModel: CardViewModel {
		let assembly = Assembly.previewAssembly
		return assembly.cardsRepository.cards[Card.testTwinCard.cardId!]!.cardModel!
	}
}
