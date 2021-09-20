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

struct CardPinSettings {
    var isPin1Default: Bool
    var isPin2Default: Bool
}

class CardViewModel: Identifiable, ObservableObject {
    //MARK: Services
    weak var featuresService: AppFeaturesService!
    var payIDService: PayIDService? = nil
    weak var tangemSdk: TangemSdk!
    weak var assembly: Assembly!
    weak var warningsConfigurator: WarningsConfigurator!
    weak var warningsAppendor: WarningAppendor!
    weak var tokenItemsRepository: TokenItemsRepository!
    weak var userPrefsService: UserPrefsService!
    
    @Published var state: State = .created
    @Published var payId: PayIdStatus = .notSupported
    @Published private(set) var currentSecOption: SecurityManagementOption = .longTap
    @Published public private(set) var cardInfo: CardInfo
    
    private var cardPinSettings: CardPinSettings?
    
    private let stateUpdateQueue = DispatchQueue(label: "state_update_queue")
    
    var availableSecOptions: [SecurityManagementOption] {
        var options = [SecurityManagementOption.longTap]
        
        if featuresService.canSetAccessCode {
            options.append(.accessCode)
        }
        
        if featuresService.canSetPasscode || isTwinCard {
            options.append(.passCode)
        }
        
        if currentSecOption != .longTap && !options.contains(currentSecOption) {
            options.append(currentSecOption)
        }
        
        return options
    }
    
    var walletModels: [WalletModel]? {
        return state.walletModels
    }
    
    var wallets: [Wallet]? {
        return walletModels?.map { $0.wallet }
    }
    
    var isMultiWallet: Bool {
        return cardInfo.card.isMultiWallet
    }
    
    var emailSupport: EmailSupport {
        isStart2CoinCard ? .start2coin : .tangem
    }
    
    var isStart2CoinCard: Bool {
        cardInfo.card.isStart2Coin
    }
    
    var canSetAccessCode: Bool {
        return cardInfo.card.settings.isSettingAccessCodeAllowed
            && featuresService.canSetAccessCode
    }
    
    var canSetPasscode: Bool {
        return cardInfo.card.settings.isSettingPasscodeAllowed
            && cardInfo.card.settings.isRemovingAccessCodeAllowed
            && (featuresService.canSetPasscode || isPairedTwin)
    }
    
    var canSetLongTap: Bool {
        return cardInfo.card.settings.isSettingPasscodeAllowed
    }
    
    var canSign: Bool {
        cardInfo.card.canSign
    }
    
    var hasWallet: Bool {
        state.walletModels != nil
    }
    
    var purgeWalletProhibitedDescription: String? {
        if isTwinCard || !hasWallet {
            return nil
        }
        
        if cardInfo.card.settings.isPermanentWallet || cardInfo.card.firmwareVersion >= .multiwalletAvailable {
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
        if cardInfo.card.firmwareVersion >= .multiwalletAvailable {
            return false
        }
        
        if cardInfo.card.wallets.count == 0 {
            return false
        }
        
        
        if cardInfo.card.settings.isPermanentWallet {
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
    
    var isSuccesfullyLoaded: Bool {
        if let walletModels = state.walletModels {
            if walletModels.contains(where: { !$0.state.isSuccesfullyLoaded }) {
                return false
            }
            
            return true
        }
        
        return false
    }
	
	var isTwinCard: Bool {
		cardInfo.card.isTwinCard
	}
    
    var isNotPairedTwin: Bool {
        isTwinCard && cardInfo.twinCardInfo?.pairPublicKey == nil
    }
    
    var isPairedTwin: Bool {
        isTwinCard && cardInfo.twinCardInfo?.pairPublicKey != nil
    }
    
    var hasBalance: Bool {
        let hasBalance = state.walletModels.map { $0.contains(where: { $0.hasBalance }) } ?? false
        
        return hasBalance
    }
    
    var canCreateTwinCard: Bool {
        guard
            isTwinCard,
            let twinInfo = cardInfo.twinCardInfo,
            twinInfo.series != nil
        else { return false }
        
        if twinInfo.pairPublicKey != nil {
            return false
        }
        
        return true
    }
	
	var canRecreateTwinCard: Bool {
		guard isTwinCard && cardInfo.twinCardInfo?.series != nil && featuresService.canCreateTwin else { return false }
		
		if case .empty = state {
			return false
		}
        
        if cardInfo.card.settings.isPermanentWallet {
            return false
        }
        
        if let walletModels = state.walletModels,
           walletModels.contains(where: { !$0.canCreateOrPurgeWallet }) {
            return false
        }
		
		return true
	}
    
    var canExchangeCrypto: Bool { featuresService.canExchangeCrypto }
    
    var isTestnet: Bool { cardInfo.isTestnet }
    
    private lazy var tokenWalletModels: [Blockchain: WalletModel] = {
        Dictionary((walletModels?.filter {
            let blockchain = $0.wallet.blockchain
            if case .ethereum = blockchain { return true }
            
            if case .bsc = blockchain { return true }
            
            return false
        } ?? []).map { ($0.wallet.blockchain, $0)}, uniquingKeysWith: { first, _ in first })
        
    }()
    
    private var searchBlockchainsCancellable: AnyCancellable? = nil
    private var bag = Set<AnyCancellable>()
    
    init(cardInfo: CardInfo) {
        self.cardInfo = cardInfo
        
        updateCurrentSecOption()
    }
    

//    func loadPayIDInfo () {
//        guard featuresService?.canReceiveToPayId ?? false else {
//            return
//        }
//
//        payIDService?
//            .loadPayIDInfo(for: cardInfo.card)
//            .subscribe(on: DispatchQueue.global())
//            .receive(on: DispatchQueue.main)
//            .sink(receiveCompletion: { completion in
//                    switch completion {
//                    case .failure(let error):
//                        print("payid load failed")
//                        Analytics.log(error: error)
//                        print(error.localizedDescription)
//                    case .finished:
//                        break
//                    }}){ [unowned self] status in
//                print("payid loaded")
//                self.payId = status
//            }
//            .store(in: &bag)
//    }

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
        
        //loadPayIDInfo()
        state.walletModels?.forEach { $0.update() }
        searchTokens()
    }
    
    func onSign(_ card: Card) {
        cardInfo.card = card
        warningsConfigurator.setupWarnings(for: cardInfo)
    }
    
    // MARK: - Security
    
    func checkPin(_ completion: @escaping (Result<CheckUserCodesResponse, Error>) -> Void) {
        tangemSdk.startSession(with: CheckUserCodesCommand(), cardId: cardInfo.card.cardId) { [weak self] (result) in
            switch result {
            case .success(let resp):
                self?.cardPinSettings = CardPinSettings(isPin1Default: !resp.isAccessCodeSet, isPin2Default: !resp.isPasscodeSet)
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
            tangemSdk.startSession(with: SetUserCodeCommand(accessCode: nil),
                                   cardId: cardInfo.card.cardId,
                                   initialMessage: Message(header: nil, body: "initial_message_change_access_code_body".localized)) {[weak self] result in
                guard let self = self else { return }
                
                switch result {
                case .success:
                    self.cardPinSettings?.isPin1Default = false
                    self.cardPinSettings?.isPin2Default = true
                    self.updateCurrentSecOption()
                    completion(.success(()))
                case .failure(let error):
                    Analytics.logCardSdkError(error, for: .changeSecOptions, card: self.cardInfo.card, parameters: [.newSecOption: "Access Code"])
                    completion(.failure(error))
                }
            }
        case .longTap:
            tangemSdk.startSession(with: SetUserCodeCommand.resetUserCodes,
                                   cardId: cardInfo.card.cardId) {[weak self] result in
                guard let self = self else { return }
                
                switch result {
                case .success:
                    self.cardPinSettings?.isPin1Default = true
                    self.cardPinSettings?.isPin2Default = true
                    self.updateCurrentSecOption()
                    completion(.success(()))
                case .failure(let error):
                    Analytics.logCardSdkError(error, for: .changeSecOptions, card: self.cardInfo.card, parameters: [.newSecOption: "Long tap"])
                    completion(.failure(error))
                }
            }
        case .passCode:
            tangemSdk.startSession(with: SetUserCodeCommand(passcode: nil),
                                   cardId: cardInfo.card.cardId,
                                   initialMessage: Message(header: nil, body: "initial_message_change_passcode_body".localized)) {[weak self] result in
                guard let self = self else { return }
                
                switch result {
                case .success:
                    self.cardPinSettings?.isPin1Default = false
                    self.cardPinSettings?.isPin2Default = true
                    self.updateCurrentSecOption()
                    completion(.success(()))
                case .failure(let error):
                    Analytics.logCardSdkError(error, for: .changeSecOptions, card: self.cardInfo.card, parameters: [.newSecOption: "Pass code"])
                    completion(.failure(error))
                }
            }
        }
    }
    
    // MARK: - Wallet
    
    func createWallet(_ completion: @escaping (Result<Void, Error>) -> Void) {
        let cid = cardInfo.card.cardId

        tangemSdk.startSession(with: CreateWalletAndReadTask(),
                               cardId: cid,
                               initialMessage: Message(header: nil,
                                                       body: "initial_message_create_wallet_body".localized)) {[unowned self] result in
            switch result {
            case .success(let card):
                self.update(with: card)
                completion(.success(()))
            case .failure(let error):
                Analytics.logCardSdkError(error, for: .createWallet, card: cardInfo.card)
                completion(.failure(error))
            }
        }
    }
    
    func purgeWallet(completion: @escaping (Result<Void, Error>) -> Void) {
        guard cardInfo.card.firmwareVersion < .multiwalletAvailable,
              let wallet = cardInfo.card.wallets.first else {
            completion(.failure(TangemSdkError.unsupportedCommand))
            return
        }
        
        tangemSdk.startSession(with: PurgeWalletAndReadTask(publicKey: wallet.publicKey),
                               cardId: cardInfo.card.cardId,
                               initialMessage: Message(header: nil,
                                                      body: "initial_message_purge_wallet_body".localized)) {[unowned self] result in
            switch result {
            case .success(let response):
                self.tokenItemsRepository.removeAll()
                self.clearTwinPairKey()
                self.update(with: response)
                completion(.success(()))
            case .failure(let error):
                Analytics.logCardSdkError(error, for: .purgeWallet, card: cardInfo.card)
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Update
    
    func getCardInfo() {
        guard cardInfo.card.firmwareVersion.type == .release else {
            return
        }
        
        tangemSdk.loadCardInfo(cardPublicKey: cardInfo.card.cardPublicKey, cardId: cardInfo.card.cardId) {[weak self] result in
            switch result {
            case .success(let info):
                guard let artwork = info.artwork else { return }

                self?.cardInfo.artworkInfo = artwork
            case .failure:
                self?.warningsAppendor.appendWarning(for: WarningEvent.failedToValidateCard)
            }
        }
    }
	
	func update(with card: Card) {
        print("🟩 Updating Card view model with new Card")
        cardInfo.card = card
        updateModel()
	}
    
    func update(with cardInfo: CardInfo) {
        print("🔷 Updating Card view model with new CardInfo")
        self.cardInfo = cardInfo
        updateModel()
    }
    
    func clearTwinPairKey() {
        cardInfo.twinCardInfo?.pairPublicKey = nil
    }
    
    func updateState() {
        print("‼️ Updating Card view model state")
        let hasWallets = cardInfo.card.wallets.count > 0

        if !hasWallets {
            self.state = .empty
        } else {
            print("⁉️ Recreating all wallet models for Card view model state")
            self.state = .loaded(walletModel: self.assembly.loadWallets(from: cardInfo))
            update()
        }
    }
    
    private func updateModel() {
        print("🔶 Updating Card view model")
        warningsConfigurator.setupWarnings(for: cardInfo)
        updateState()
    }
    
    private func updateLoadedState(with newWalletModels: [WalletModel]) {
        stateUpdateQueue.sync {
            if let existingWalletModels = self.walletModels {
                var itemsToAdd: [WalletModel] = []
                for model in newWalletModels {
                    if !existingWalletModels.contains(where: { $0.wallet.blockchain == model.wallet.blockchain }) {
                        itemsToAdd.append(model)
                    }
                }
                if !itemsToAdd.isEmpty {
                    state = .loaded(walletModel: existingWalletModels + itemsToAdd)
                }
            }
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
        
        let unusedBlockhains = tokenItemsRepository.supportedItems.blockchains(for: cardInfo).subtracting(currentBlockhains).map { $0 }
        let models = assembly.makeWallets(from: cardInfo, blockchains: unusedBlockhains)
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
                    updateLoadedState(with: notEmptyWallets)
                }
            })
        
        models.forEach { $0.update() }
    }
    
    private func searchTokens() {
        guard cardInfo.card.isMultiWallet,
            !userPrefsService.searchedCards.contains(cardInfo.card.cardId) else {
            return
        }
        
        var sholdAddWalletManager = false
        let blockchain: Blockchain = .ethereum(testnet: isTestnet)
        var ethWalletModel = tokenWalletModels[blockchain]
        
        if ethWalletModel == nil {
            sholdAddWalletManager = true
            ethWalletModel = assembly.makeWallets(from: cardInfo, blockchains: [blockchain]).first!
        }
        
        (ethWalletModel!.walletManager as! TokenFinder).findErc20Tokens() {[weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let tokensAdded):
                if tokensAdded {
                    var tokens = ethWalletModel!.walletManager.cardTokens
                    if let defaultToken = self.cardInfo.defaultToken {
                        tokens = tokens.filter { $0 != defaultToken }
                    }
                    let tokenItems = tokens.map { TokenItem.token($0) }
                    self.tokenItemsRepository.append(tokenItems)
                    
                    if sholdAddWalletManager {
                        self.tokenItemsRepository.append(.blockchain(ethWalletModel!.wallet.blockchain))
                        self.stateUpdateQueue.sync {
                            self.state = .loaded(walletModel: self.walletModels! + [ethWalletModel!])
                        }
                        ethWalletModel!.update()
                    }
                }
            case .failure(let error):
                print(error)
            }
            
            self.userPrefsService.searchedCards.append(self.cardInfo.card.cardId)
            self.searchBlockchains()
        }
    }
    
    func addToken(_ token: BlockchainSdk.Token, blockchain: Blockchain, completion: @escaping (Result<BlockchainSdk.Token, Error>) -> Void) {
        let walletModel: WalletModel? = tokenWalletModels[blockchain] ?? addBlockchain(blockchain)
        if tokenWalletModels[blockchain] == nil, let model = walletModel {
            tokenWalletModels[blockchain] = model
        }
        
        walletModel?.addToken(token)?.sink(receiveCompletion: { addCompletion in
            if case let .failure(error) = addCompletion {
                print("Failed to add token to model", error)
                completion(.failure(error))
            }
        }, receiveValue: { _ in
            self.updateState()
            completion(.success(token))
        })
        .store(in: &self.bag)
    }
  
    @discardableResult
    func addBlockchain(_ blockchain: Blockchain) -> WalletModel? {
        tokenItemsRepository.append(.blockchain(blockchain))
        let newWalletModels = assembly.makeWallets(from: cardInfo, blockchains: [blockchain])
        newWalletModels.forEach {$0.update()}
        updateLoadedState(with: newWalletModels)
        return newWalletModels.first
    }
    
    func removeBlockchain(_ blockchain: Blockchain) {
        guard canRemoveBlockchain(blockchain) else {
            return
        }
        
        tokenWalletModels[blockchain] = nil
        tokenItemsRepository.remove(.blockchain(blockchain))
        
        stateUpdateQueue.sync {
            if let walletModels = self.walletModels {
                state = .loaded(walletModel: walletModels.filter { $0.wallet.blockchain != blockchain })
            }
        }
    }
    
    func canRemoveBlockchain(_ blockchain: Blockchain) -> Bool {
        if let defaultBlockchain = cardInfo.defaultBlockchain,
           defaultBlockchain == blockchain {
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
        if !(cardPinSettings?.isPin1Default ?? true) {
            self.currentSecOption = .accessCode
        } else if !(cardPinSettings?.isPin2Default ?? true) {
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
    static func previewViewModel(for card: Assembly.PreviewCard) -> CardViewModel {
        Assembly.previewCardViewModel(for: card)
    }
}
