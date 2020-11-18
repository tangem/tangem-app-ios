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
    weak var workaroundsService: WorkaroundsService!
    weak var payIDService: PayIDService? = nil
    var config: Config!
    weak var tangemSdk: TangemSdk!
    weak var assembly: Assembly!
    
    @Published var state: State = .created
    @Published var payId: PayIdStatus = .notSupported
    @Published private(set) var currentSecOption: SecurityManagementOption = .longTap
    
    var canSign: Bool {
        let isPin2Default = cardInfo.card.isPin2Default ?? true
        let hasSmartSecurityDelay = cardInfo.card.settingsMask?.contains(.smartSecurityDelay) ?? false
        let canSkipSD = hasSmartSecurityDelay && !isPin2Default
        
        if let fw = cardInfo.card.firmwareVersionValue, fw < 2.28 {
            if let securityDelay = cardInfo.card.pauseBeforePin2, securityDelay > 1500 && !canSkipSD {
                return false
            }
        }
        
        return true
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
            
            if !walletModel.wallet.isEmptyAmount || walletModel.wallet.hasPendingTx {
                return false
            }
            
            return true
        } else {
            return false
        }
    }
	
	var isTwinCard: Bool {
		// [REDACTED_TODO_COMMENT]
		if !(cardInfo.card.cardData?.productMask?.contains(.note) ?? false) {
			return false
		}
		
		if let status = cardInfo.card.status, status == .empty {
			return false
		}
		
		return true
	}
    
    var canManageSecurity: Bool {
        cardInfo.card.isPin1Default != nil &&
            cardInfo.card.isPin2Default != nil
    }
    
    var canTopup: Bool { config.isEnableMoonPay && workaroundsService.isTopupSupported(for: cardInfo.card) }
    
    public private(set) var cardInfo: CardInfo {
        didSet {
            updateState()
        }
    }
    
    private var bag =  Set<AnyCancellable>()
    
    init(cardInfo: CardInfo) {
        self.cardInfo = cardInfo
        updateCurrentSecOption()
    }
    
    func loadPayIDInfo () {
        payIDService?
            .loadPayIDInfo(for: cardInfo.card)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                    switch completion {
                    case .failure(let error):
                        Analytics.log(error: error)
                        print(error.localizedDescription)
                    case .finished:
                        break
                    }}){ [unowned self] status in
                self.payId = status
            }
            .store(in: &bag)
    }

    func createPayID(_ payIDString: String, completion: @escaping (Result<Void, Error>) -> Void) { //todo: move to payidservice
        guard !payIDString.isEmpty,
            let cid = cardInfo.card.cardId,
            let cardPublicKey = cardInfo.card.cardPublicKey,
            let payIdService = self.payIDService,
            let address = state.wallet?.address  else {
                completion(.failure(PayIdError.unknown))
                return
        }

        let fullPayIdString = payIDString + "$payid.tangem.com"
        payIdService.createPayId(cid: cid, key: cardPublicKey,
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
    
    func update(silent: Bool = false) {
        loadPayIDInfo()
        state.walletModel?.update(silent: silent)
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
                self.cardInfo.card = self.cardInfo.card.updating(with: response)
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
                self.cardInfo.card = self.cardInfo.card.updating(with: response)
                completion(.success(()))
            case .failure(let error):
                Analytics.log(error: error)
                completion(.failure(error))
            }
        }
    }
    
    func updateState() {
        if let wm = self.assembly.makeWalletModel(from: cardInfo.card) {
            self.state = .loaded(walletModel: wm)
        } else {
            self.state = .empty
        }
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
}
