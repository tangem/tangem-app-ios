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
    weak var warningsConfigurator: WarningsConfigurator!
    weak var walletItemsRepository: WalletItemsRepository!
    
    @Published var state: State = .created
    @Published var payId: PayIdStatus = .notSupported
    @Published private(set) var currentSecOption: SecurityManagementOption = .longTap
    @Published public private(set) var cardInfo: CardInfo
    
    var erc20TokenWalletModel: WalletModel {
        get {
            if let ethWallet = walletModels!.first(where: {$0.wallet.blockchain == .ethereum(testnet: true)
                                                                    || $0.wallet.blockchain == .ethereum(testnet: false)}) {
                return ethWallet
            }
           
            let newEthWallet = addBlockchain(.ethereum(testnet: cardInfo.card.isTestnet))
            return newEthWallet
        }
    }
    
    var walletModels: [WalletModel]? {
        return state.walletModels
    }
    
    var walletItemViewModels: [WalletItemViewModel]? {
        walletModels?
            .flatMap ({ $0.walletItems })
            .sorted(by: { lhs, rhs in
                if lhs.blockchain == cardInfo.card.blockchain {
                    return true
                }
                
                if rhs.blockchain == cardInfo.card.blockchain {
                    return false
                }
                
                if lhs.fiatBalance != " " && rhs.fiatBalance == " " {
                    return true
                }
                
                if lhs.fiatBalance == " " && rhs.fiatBalance != " " {
                    return false
                }
                
                if lhs.fiatBalance != " " && rhs.fiatBalance != " " && lhs.fiatBalance != rhs.fiatBalance {
                    return lhs.fiatBalance > rhs.fiatBalance
                }
                
                return lhs.blockchain.displayName < rhs.blockchain.displayName
            })
    }
    
    var wallets: [Wallet]? {
        return walletModels?.map { $0.wallet }
    }
    
    var isMultiWallet: Bool {
        return cardInfo.isMultiWallet
    }
    
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
        state.walletModels != nil
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
        
        if let walletModels = state.walletModels {
            if walletModels.contains(where: { !$0.canCreateOrPurgeWallet }) {
                return false
            }
            
            return true
        }
        
        return false
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
        
        if let walletModels = state.walletModels,
           walletModels.contains(where: { !$0.canCreateOrPurgeWallet }) {
            return false
        }
		
		return true
	}
    
    var canManageSecurity: Bool {
        cardInfo.card.isPin1Default != nil &&
            cardInfo.card.isPin2Default != nil
    }
    
    var canTopup: Bool { featuresService.canTopup }
    
    private var searchBlockchainsCancellable: AnyCancellable? = nil
    private var bag =  Set<AnyCancellable>()
    
    init(cardInfo: CardInfo) {
        self.cardInfo = cardInfo
        
        updateCurrentSecOption()
    }
    
    func loadPayIDInfo () {
        guard featuresService?.canReceiveToPayId ?? false else {
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

//    func createPayID(_ payIDString: String, completion: @escaping (Result<Void, Error>) -> Void) { //todo: move to payidservice
//        guard featuresService.canReceiveToPayId,
//              !payIDString.isEmpty,
//              let cid = cardInfo.card.cardId,
//              let payIDService = self.payIDService,
//              let cardPublicKey = cardInfo.card.cardPublicKey,
//              let address = state.wallet?.address  else {
//            completion(.failure(PayIdError.unknown))
//            return
//        }
//
//        let fullPayIdString = payIDString + "$payid.tangem.com"
//        payIDService.createPayId(cid: cid, key: cardPublicKey,
//                                 payId: fullPayIdString,
//                                 address: address) { [weak self] result in
//            switch result {
//            case .success:
//                UIPasteboard.general.string = fullPayIdString
//                self?.payId = .created(payId: fullPayIdString)
//                completion(.success(()))
//            case .failure(let error):
//                Analytics.log(error: error)
//                completion(.failure(error))
//            }
//        }
//
//    }
    
    func update() {
        guard state.canUpdate else {
            return
        }
        
        loadPayIDInfo()
        state.walletModels?.forEach { $0.update() }
    }
    
    func onSign(_ signResponse: SignResponse) {
        cardInfo.card.walletSignedHashes = signResponse.walletSignedHashes
    }
    
    func checkPin(_ completion: @escaping (Result<CheckPinResponse, Error>) -> Void) {
        tangemSdk.startSession(with: CheckPinCommand(), cardId: cardInfo.card.cardId) { [weak self] (result) in
            switch result {
            case .success(let resp):
                self?.cardInfo.card.isPin1Default = resp.isPin1Default
                self?.cardInfo.card.isPin2Default = resp.isPin2Default
                self?.updateCurrentSecOption()
                completion(.success(resp))
            case .failure(let error):
                completion(.failure(error))
            }
        }
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
                self.warningsConfigurator.setupWarnings(for: card)
                self.cardInfo.card = card
                self.updateState()
                completion(.success(()))
            case .failure(let error):
                Analytics.log(error: error)
                completion(.failure(error))
            }
        }
    }
    
    func getCardInfo() {
        tangemSdk.getCardInfo(cardId: cardInfo.card.cardId ?? "", cardPublicKey: cardInfo.card.cardPublicKey ?? Data()) {[weak self] result in
            if case let .success(info) = result,
               let artwork = info.artwork {
                self?.cardInfo.artworkInfo = artwork
            }
        }
    }
	
	func update(withCreateWaletResponse response: CreateWalletResponse) {
        let card = cardInfo.card.updating(with: response)
		cardInfo.card = card
		if card.isTwinCard {
			cardInfo.twinCardInfo?.pairPublicKey = nil
		}
        warningsConfigurator.setupWarnings(for: card)
		updateState()
	}
    
    func update(with cardInfo: CardInfo) {
        self.cardInfo = cardInfo
        updateState()
    }
    
    func updateState() {
        if let wm = self.assembly.makeWalletModel(from: cardInfo) {
            self.state = .loaded(walletModel: wm)
            searchBlockchains()
        } else {
            self.state = .empty
        }
        
        update()
    }
    
    func searchBlockchains() {
        guard cardInfo.isMultiWallet else {
            return
        }
        
        searchBlockchainsCancellable = nil
        
        guard let currentBlockhains = wallets?.map({ $0.blockchain }) else {
            return
        }
        
        let unusedBlockhains = walletItemsRepository.supportedWalletItems.blockchains.subtracting(currentBlockhains).map { WalletItem.blockchain($0) }
        
        if let walletModels = assembly.makeWalletModels(from: cardInfo, items: unusedBlockhains) {
            searchBlockchainsCancellable =
                Publishers.MergeMany(walletModels.map { $0.$state.dropFirst() })
                .collect(walletModels.count)
                .sink(receiveValue: { [unowned self] _ in
                    let notEmptyWallets = walletModels.filter { !$0.wallet.isEmpty }
                    if notEmptyWallets.count > 0 {
                        walletItemsRepository.append(notEmptyWallets.map({WalletItem.blockchain($0.wallet.blockchain)}))
                        self.state = .loaded(walletModel: self.walletModels! + notEmptyWallets)
                    }
                })
            
            walletModels.forEach { $0.update() }
        }
    }
    
    @discardableResult
    func addBlockchain(_ blockchain: Blockchain) -> WalletModel {
        let wi: WalletItem = .blockchain(blockchain)
        walletItemsRepository.append(wi)
        let newWallet = assembly.makeWalletModels(from: cardInfo, items: [wi])!.first!
        state = .loaded(walletModel: walletModels! + [newWallet])
        newWallet.update()
        return newWallet
    }
    
    func removeBlockchain(_ blockchain: Blockchain) {
        guard canRemoveBlockchain(blockchain) else {
            return
        }
        
        walletItemsRepository.remove(.blockchain(blockchain))
        state = .loaded(walletModel: walletModels!.filter { $0.wallet.blockchain != blockchain })
    }
    
    func canRemoveBlockchain(_ blockchain: Blockchain) -> Bool {
        guard cardInfo.card.blockchain != blockchain else {
            return false
        }
        
        if let walletModels = walletModels {
            for walletModel in walletModels {
                if !walletModel.canRemove(amountType: .coin) {
                    return false
                }
            }
        }
        
        return true
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
        case loaded(walletModel: [WalletModel])
        
        var walletModels: [WalletModel]? {
            switch self {
            case .loaded(let models):
                return models
            default:
                return nil
            }
        }
        
//
//        var wallet: Wallet? {
//            switch self {
//            case .loaded(let model):
//                return model.wallet
//            default:
//                return nil
//            }
//        }
        
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
        viewModel(for: Card.testCard)
    }
    
    static var previewCardViewModelNoWallet: CardViewModel {
        viewModel(for: Card.testCardNoWallet)
    }
	
	static var previewTwinCardViewModel: CardViewModel {
		viewModel(for: Card.testTwinCard)
	}
    
    static var previewEthCardViewModel: CardViewModel {
        viewModel(for: Card.testEthCard)
    }
    
    private static func viewModel(for card: Card) -> CardViewModel {
        let assembly = Assembly.previewAssembly
        return assembly.cardsRepository.cards[card.cardId!]!.cardModel!
    }
}
