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
    weak var warningsAppendor: WarningAppendor!
    weak var tokenItemsRepository: TokenItemsRepository!
    
    @Published var state: State = .created
    @Published var payId: PayIdStatus = .notSupported
    @Published private(set) var currentSecOption: SecurityManagementOption = .longTap
    @Published public private(set) var cardInfo: CardInfo
    
    var walletModels: [WalletModel]? {
        return state.walletModels
    }
    
    var wallets: [Wallet]? {
        return walletModels?.map { $0.wallet }
    }
    
    var isMultiWallet: Bool {
        return cardInfo.card.isMultiWallet
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
        
        if let walletModels = walletModels,
           walletModels.filter({ !$0.state.isSuccesfullyLoaded }).count != 0  {
            return nil
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
    
    private var erc20TokenWalletModel: WalletModel? {
        get {
             walletModels?.first(where: {$0.wallet.blockchain == .ethereum(testnet: true)
                                                                    || $0.wallet.blockchain == .ethereum(testnet: false)})
        }
    }
    
    private var searchBlockchainsCancellable: AnyCancellable? = nil
    private var bag = Set<AnyCancellable>()
    
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
    
    // MARK: - Security
    
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
    
    // MARK: - Wallet
    
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
    
    // MARK: - Update
    
    func getCardInfo() {
        guard cardInfo.card.cardType == .release else {
            return
        }
        
        tangemSdk.getCardInfo(cardId: cardInfo.card.cardId ?? "", cardPublicKey: cardInfo.card.cardPublicKey ?? Data()) {[weak self] result in
            switch result {
            case .success(let info):
                guard let artwork = info.artwork else { return }

                self?.cardInfo.artworkInfo = artwork
            case .failure:
                self?.warningsAppendor.appendWarning(for: WarningEvent.failedToValidateCard)
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
        let models = self.assembly.makeWalletModel(from: cardInfo)
        
        if models.isEmpty {
            self.state = .empty
        } else {
            self.state = .loaded(walletModel: models)
            searchTokens()
            update()
        }
    }
    
    private func searchBlockchains() {
        guard cardInfo.card.isMultiWallet else {
            return
        }
        
        searchBlockchainsCancellable = nil
        
        guard let currentBlockhains = wallets?.map({ $0.blockchain }) else {
            return
        }
        
        let unusedBlockhains = tokenItemsRepository.supportedItems.blockchains.subtracting(currentBlockhains).map { $0 }
        let models = assembly.makeWalletModels(from: cardInfo, blockchains: unusedBlockhains)
        if models.isEmpty {
            return
        }
        
        searchBlockchainsCancellable =
            Publishers.MergeMany(models.map { $0.$state.dropFirst() })
            .collect(models.count)
            .sink(receiveValue: { [unowned self] _ in
                let notEmptyWallets = models.filter { !$0.wallet.isEmpty }
                if notEmptyWallets.count > 0 {
                    tokenItemsRepository.append(notEmptyWallets.map({TokenItem.blockchain($0.wallet.blockchain)}))
                    self.state = .loaded(walletModel: self.walletModels! + notEmptyWallets)
                }
            })
        
        models.forEach { $0.update() }
    }
    
    private func searchTokens() {
        guard cardInfo.card.isMultiWallet else {
            return
        }
        
        var sholdAddWalletManager = false
        var ethWalletModel = erc20TokenWalletModel
        
        if ethWalletModel == nil {
            sholdAddWalletManager = true
            ethWalletModel = assembly.makeWalletModels(from: cardInfo, blockchains: [.ethereum(testnet: cardInfo.card.isTestnet)]).first!
        }
        
        (ethWalletModel!.walletManager as! TokenFinder).findErc20Tokens() { result in
            switch result {
            case .success(let isAdded):
                if isAdded && sholdAddWalletManager {
                    self.state = .loaded(walletModel: self.walletModels! + [ethWalletModel!])
                    ethWalletModel!.update()
                }
            case .failure(let error):
                print(error)
            }
            
            self.searchBlockchains()
        }
    }
    
    func addToken(_ token: Token, completion: @escaping (Result<Token, Error>) -> Void) {
        var ehhWalletModel = erc20TokenWalletModel
        if ehhWalletModel == nil {
            ehhWalletModel = addBlockchain(.ethereum(testnet: cardInfo.card.isTestnet))
        }
        
        ehhWalletModel?.addToken(token)?
            .sink(receiveCompletion: { addCompletion in
                if case let .failure(error) = addCompletion {
                    print("Failed to add token to model", error)
                    completion(.failure(error))
                }
            }, receiveValue: { _ in
                completion(.success(token))
            })
            .store(in: &bag)
    }
  
    @discardableResult
    func addBlockchain(_ blockchain: Blockchain) -> WalletModel {
        tokenItemsRepository.append(.blockchain(blockchain))
        
        let newWallet = assembly.makeWalletModels(from: cardInfo, blockchains: [blockchain]).first!
        state = .loaded(walletModel: walletModels! + [newWallet])
        newWallet.update()
        return newWallet
    }
    
    func removeBlockchain(_ blockchain: Blockchain) {
        guard canRemoveBlockchain(blockchain) else {
            return
        }
        
        tokenItemsRepository.remove(.blockchain(blockchain))
        state = .loaded(walletModel: walletModels!.filter { $0.wallet.blockchain != blockchain })
    }
    
    func canRemoveBlockchain(_ blockchain: Blockchain) -> Bool {
        guard cardInfo.card.blockchain != blockchain else {
            return false
        }
        
        if let walletModel = walletModels?.first(where: { $0.wallet.blockchain == blockchain}) {
            if !walletModel.canRemove(amountType: .coin) {
                return false
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
        return assembly.services.cardsRepository.cards[card.cardId!]!.cardModel!
    }
}
