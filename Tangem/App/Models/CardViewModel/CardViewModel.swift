//
//  CardViewModel.swift
//  Tangem
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
    var isPin1Default: Bool? = nil
    var isPin2Default: Bool? = nil
}

class CardViewModel: Identifiable, ObservableObject {
    //MARK: Services
    weak var featuresService: AppFeaturesService!
    weak var tangemSdk: TangemSdk!
    weak var assembly: Assembly!
    weak var warningsConfigurator: WarningsConfigurator!
    weak var warningsAppendor: WarningAppendor!
    weak var tokenItemsRepository: TokenItemsRepository!
    weak var userPrefsService: UserPrefsService!
    weak var imageLoaderService: CardImageLoaderService!
    weak var tokenListService: TokenListService!
    
    @Published var state: State = .created
    @Published var payId: PayIdStatus = .notSupported
    @Published private(set) var currentSecOption: SecurityManagementOption = .longTap
    @Published public var cardInfo: CardInfo
    
    private var cardPinSettings: CardPinSettings = CardPinSettings()
    
    private let stateUpdateQueue = DispatchQueue(label: "state_update_queue")
    
    var availableSecOptions: [SecurityManagementOption] {
        var options = [SecurityManagementOption.longTap]
        
        if featuresService.canSetAccessCode || currentSecOption == .accessCode {
            options.append(.accessCode)
        }
        
        if featuresService.canSetPasscode || isTwinCard || currentSecOption == .passCode {
            options.append(.passCode)
        }
        
        return options
    }
    
    var walletModels: [WalletModel]? {
        return state.walletModels
    }
    
    var wallets: [Wallet]? {
        return walletModels?.map { $0.wallet }
    }
    
    var emailSupport: EmailSupport {
        isStart2CoinCard ? .start2coin : .tangem
    }
    
    var isStart2CoinCard: Bool {
        cardInfo.card.isStart2Coin
    }
    
    var canSetAccessCode: Bool {
        if cardInfo.isTangemWallet {
            return cardInfo.card.settings.isSettingAccessCodeAllowed
        }
        
        return cardInfo.card.settings.isSettingAccessCodeAllowed
            && featuresService.canSetAccessCode
    }
    
    var canSetPasscode: Bool {
        if cardInfo.isTangemWallet {
            return cardInfo.card.settings.isSettingPasscodeAllowed
        }
        
        return cardInfo.card.settings.isSettingPasscodeAllowed
            /*&& cardInfo.card.settings.isRemovingAccessCodeAllowed*/ //Disable temporary because of sdk inverted mapping bug
            && (featuresService.canSetPasscode || isPairedTwin)
    }
    
    var canSetLongTap: Bool {
        return cardInfo.card.settings.isResettingUserCodesAllowed
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
        
        if cardInfo.card.wallets.contains(where: { $0.settings.isPermanent }){
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
        if cardInfo.card.wallets.isEmpty {
            return false
        }
        
        if cardInfo.card.wallets.contains(where: { $0.settings.isPermanent }) {
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
            let twinInfo = cardInfo.twinCardInfo
//            twinInfo.series != nil
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
        
        if cardInfo.card.wallets.first?.settings.isPermanent ?? false {
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
    
    var cachedImage: UIImage? = nil
    
    var imageLoaderPublisher: AnyPublisher<UIImage, Never> {
        if let cached = cachedImage {
            return Just(cached).eraseToAnyPublisher()
        }
        
        return $cardInfo
            .filter { $0.artwork != .notLoaded || $0.card.isTwinCard }
            .map { $0.imageLoadDTO }
            .removeDuplicates()
            .flatMap {[weak self] info -> AnyPublisher<UIImage, Never> in
                guard let self = self else {
                    return Just(UIImage()).eraseToAnyPublisher()
                }
                
                return self.imageLoaderService
                    .loadImage(cid: info.cardId,
                               cardPublicKey: info.cardPublicKey,
                               artworkInfo: info.artwotkInfo)
                    .map {[weak self] (image, canBeCached) -> UIImage in
                        if canBeCached {
                            self?.cachedImage = image
                        }
                        
                        return image
                    }
                    .eraseToAnyPublisher()
            }
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }
    
    private var searchBlockchainsCancellable: AnyCancellable? = nil
    private var bag = Set<AnyCancellable>()
    
    init(cardInfo: CardInfo) {
        self.cardInfo = cardInfo
        updateCardPinSettings()
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
        
        tryMigrateTokens() { [weak self] upgraded in
            if !upgraded {
                self?.state.walletModels?.forEach { $0.update() }
            }
            
            self?.searchTokens()
        }
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
                    self.cardPinSettings.isPin1Default = false
                    self.cardPinSettings.isPin2Default = true
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
                    self.cardPinSettings.isPin1Default = true
                    self.cardPinSettings.isPin2Default = true
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
                    self.cardPinSettings.isPin1Default = true
                    self.cardPinSettings.isPin2Default = false
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
        let card = self.cardInfo.card
        tangemSdk.startSession(with: CreateWalletAndReadTask(with: cardInfo.defaultBlockchain?.curve),
                               cardId: cardInfo.card.cardId,
                               initialMessage: Message(header: nil,
                                                       body: "initial_message_create_wallet_body".localized)) {[weak self] result in
            switch result {
            case .success(let card):
                self?.update(with: card)
                completion(.success(()))
            case .failure(let error):
                Analytics.logCardSdkError(error, for: .createWallet, card: card)
                completion(.failure(error))
            }
        }
    }
    
    func resetToFactory(completion: @escaping (Result<Void, Error>) -> Void) {
        let card = self.cardInfo.card
        tangemSdk.startSession(with: ResetToFactorySettingsTask(),
                               cardId: cardInfo.card.cardId,
                               initialMessage: Message(header: nil,
                                                       body: "initial_message_purge_wallet_body".localized)) { [weak self] result in
            switch result {
            case .success(let response):
                self?.tokenItemsRepository.removeAll(for: response.cardId)
                self?.clearTwinPairKey()
               // self.update(with: response)
                completion(.success(()))
            case .failure(let error):
                Analytics.logCardSdkError(error, for: .purgeWallet, card: card)
                completion(.failure(error))
            }
        }
    }
    
    func deriveKeys(derivationPaths:  [Data: [DerivationPath]], completion: @escaping (Result<Void, Error>) -> Void) {
        let card = self.cardInfo.card
        
        tangemSdk.startSession(with: DeriveMultipleWalletPublicKeysTask(derivationPaths), cardId: card.cardId) {[weak self] result in
            switch result {
            case .success(let newDerivations):
                self?.updateDerivations(with: newDerivations)
                completion(.success(()))
            case .failure(let error):
                Analytics.logCardSdkError(error, for: .purgeWallet, card: card)
                completion(.failure(error))
            }
        }
    }
    
    func updateDerivations(with newDerivations: [Data: [DerivationPath:ExtendedPublicKey]]) {
        for newKey in newDerivations {
            for newDerivation in newKey.value {
                self.cardInfo.derivedKeys[newKey.key, default: [:]][newDerivation.key] = newDerivation.value
            }
        }
    }
    
    // MARK: - Update
    
    func getCardInfo() {
        cardInfo.artwork = .notLoaded
        guard cardInfo.card.firmwareVersion.type == .release else {
            cardInfo.artwork = .noArtwork
            return
        }
        
        tangemSdk.loadCardInfo(cardPublicKey: cardInfo.card.cardPublicKey, cardId: cardInfo.card.cardId) {[weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let info):
                guard let artwork = info.artwork else { return }

                self.cardInfo.artwork = .artwork(artwork)
            case .failure:
                self.cardInfo.artwork = .noArtwork
                self.warningsConfigurator.setupWarnings(for: self.cardInfo)
            }
        }
    }
	
	func update(with card: Card) {
        print("🟩 Updating Card view model with new Card")
        cardInfo.card = card
        updateCardPinSettings()
        self.updateCurrentSecOption()
        updateModel()
	}
    
    func update(with cardInfo: CardInfo) {
        print("🔷 Updating Card view model with new CardInfo")
        self.cardInfo = cardInfo
        updateCardPinSettings() 
        self.updateCurrentSecOption()
        updateModel()
    }
    
    func clearTwinPairKey() {
        cardInfo.twinCardInfo?.pairPublicKey = nil
    }
    
    func updateState() {
        print("‼️ Updating Card view model state")
        let hasWallets = !cardInfo.card.wallets.isEmpty

        if !hasWallets {
            self.state = .empty
        } else {
            print("⁉️ Recreating all wallet models for Card view model state")
            self.state = .loaded(walletModel: self.assembly.makeAllWalletModels(from: cardInfo))
            
            if !userPrefsService.cardsStartedActivation.contains(cardInfo.card.cardId) || cardInfo.isTangemWallet {
                update()
            }
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
                    if !existingWalletModels.contains(where: { $0.blockchainNetwork == model.blockchainNetwork }) {
                        itemsToAdd.append(model)
                    }
                }
                if !itemsToAdd.isEmpty {
                    state = .loaded(walletModel: (existingWalletModels + itemsToAdd)/*.sorted{ $0.wallet.blockchain.displayName < $1.wallet.blockchain.displayName}*/)
                }
            }
        }
    }
    
    private func searchBlockchains() {
        guard cardInfo.isMultiWallet else {
            return
        }
        
        searchBlockchainsCancellable = nil
        
        guard let currentBlockhains = wallets?.map({ $0.blockchain }) else {
            return
        }
        
        let supportedItems = SupportedTokenItems()
        let unused: [StorageEntry] = supportedItems.blockchains(for: cardInfo.card.walletCurves, isTestnet: cardInfo.isTestnet)
            .subtracting(currentBlockhains).map { StorageEntry(blockchainNetwork: .init($0, derivationPath: nil), tokens: []) }
        let models = assembly.makeWalletModels(from: cardInfo, entries: unused)
        if models.isEmpty {
            return
        }
        
        searchBlockchainsCancellable =
            Publishers.MergeMany(models.map { $0.$state.dropFirst() })
            .collect(models.count)
            .sink(receiveValue: { [unowned self] _ in
                let notEmptyWallets = models.filter { !$0.wallet.isEmpty }
                if !notEmptyWallets.isEmpty {
                    let itemsToAdd = notEmptyWallets.map { $0.blockchainNetwork }
                    tokenItemsRepository.append(itemsToAdd, for: cardInfo.card.cardId)
                    updateLoadedState(with: notEmptyWallets)
                }
            })
        
        models.forEach { $0.update() }
    }
    
    private func searchTokens() {
        guard cardInfo.isMultiWallet, !cardInfo.isTangemWallet,
            !userPrefsService.searchedCards.contains(cardInfo.card.cardId) else {
            return
        }
        
        var shouldAddWalletManager = false
        let ethBlockchain = Blockchain.ethereum(testnet: isTestnet)
        let network = BlockchainNetwork(ethBlockchain, derivationPath: nil)
        var ethWalletModel = walletModels?.first(where: { $0.blockchainNetwork == network })
        
        if ethWalletModel == nil {
            shouldAddWalletManager = true
            let entry = StorageEntry(blockchainNetwork: network, tokens: [])
            ethWalletModel = assembly.makeWalletModels(from: cardInfo, entries: [entry]).first
        }
        
        guard let tokenFinder = ethWalletModel?.walletManager as? TokenFinder else {
            self.userPrefsService.searchedCards.append(self.cardInfo.card.cardId)
            self.searchBlockchains()
            return
        }
        
        
        tokenFinder.findErc20Tokens(knownTokens: []) {[weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let tokensAdded):
                if tokensAdded {
                    var tokens = ethWalletModel!.walletManager.cardTokens
                    if let defaultToken = self.cardInfo.defaultToken {
                        tokens = tokens.filter { $0 != defaultToken }
                    }
                    
                    self.tokenItemsRepository.append(tokens, blockchainNetwork: network, for: self.cardInfo.card.cardId)
                    
                    if shouldAddWalletManager {
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
    
    func add(items: [(Amount.AmountType, BlockchainNetwork)], completion: @escaping (Result<Void, Error>) -> Void) {
        var entries: [StorageEntry] = []
        
        items.forEach { item in
            if let index = entries.firstIndex(where: { $0.blockchainNetwork == item.1 }) {
                if let token = item.0.token, !entries[index].tokens.contains(token) {
                    entries[index].tokens.append(token)
                }
            } else {
                let tokens = item.0.token.map { [$0] } ?? []
                entries.append(StorageEntry(blockchainNetwork: item.1, tokens: tokens))
            }
        }
        
        tokenItemsRepository.append(entries, for: cardInfo.card.cardId)
        
        if cardInfo.card.settings.isHDWalletAllowed {
            var newDerivationPaths: [Data: [DerivationPath]] = [:]
            
            entries.forEach { entry in
                if let path = entry.blockchainNetwork.derivationPath,
                   let publicKey = cardInfo.card.wallets.first(where: { $0.curve == entry.blockchainNetwork.blockchain.curve })?.publicKey,
                   cardInfo.derivedKeys[publicKey]?[path] == nil {
                    newDerivationPaths[publicKey, default: []].append(path)
                }
            }

            if newDerivationPaths.isEmpty {
                finishAddingTokens(entries, completion: completion)
                return
            }
            
            deriveKeys(derivationPaths: newDerivationPaths) { result in
                switch result {
                case .success:
                    self.finishAddingTokens(entries, completion: completion)
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } else {
            finishAddingTokens(entries, completion: completion)
        }
    }
    
    private func finishAddingTokens(_ entries: [StorageEntry], completion: @escaping (Result<Void, Error>) -> Void) {
        guard let walletModels = self.walletModels else {
            completion(.success(()))
            return
        }
        
        let newWalletModels = assembly.makeWalletModels(from: cardInfo, entries: entries)
        newWalletModels.forEach { $0.update() }
        
        entries.forEach { entry in
            if let existingWalletModel = walletModels.first(where: { $0.blockchainNetwork == entry.blockchainNetwork }) {
                existingWalletModel.addTokens(entry.tokens)
                existingWalletModel.update()
            }
        }
        
        updateLoadedState(with: newWalletModels)
        completion(.success(()))
    }
    
    func canManage(amountType: Amount.AmountType, blockchainNetwork: BlockchainNetwork) -> Bool {
        if let walletModel = walletModels?.first(where: { $0.blockchainNetwork == blockchainNetwork }) {
            return walletModel.canRemove(amountType: amountType)
        }
        
        return true
    }
    
    func canRemove(amountType: Amount.AmountType, blockchainNetwork: BlockchainNetwork) -> Bool {
        if let walletModel = walletModels?.first(where: { $0.blockchainNetwork == blockchainNetwork }) {
            return walletModel.canRemove(amountType: amountType)
        }

        return false
    }
    
    func remove(items: [(Amount.AmountType, BlockchainNetwork)]) {
        items.forEach {
            remove(amountType: $0.0, blockchainNetwork: $0.1)
        }
    }
    
    func remove(amountType: Amount.AmountType, blockchainNetwork: BlockchainNetwork) {
        guard canRemove(amountType: amountType, blockchainNetwork: blockchainNetwork) else {
            return
        }
        
        if amountType == .coin {
            removeBlockchain(blockchainNetwork)
        } else if case let .token(token) = amountType {
            removeToken(token, blockchainNetwork: blockchainNetwork)
        }
    }
    
    private func removeBlockchain(_ blockchainNetwork: BlockchainNetwork) {
        tokenItemsRepository.remove([blockchainNetwork], for: cardInfo.card.cardId)
        
        stateUpdateQueue.sync {
            if let walletModels = self.walletModels {
                state = .loaded(walletModel: walletModels.filter { $0.blockchainNetwork != blockchainNetwork })
            }
        }
    }
    
    private func removeToken(_ token: BlockchainSdk.Token, blockchainNetwork: BlockchainNetwork) {
        if let walletModel = walletModels?.first(where: { $0.blockchainNetwork == blockchainNetwork}) {
            let isRemoved = walletModel.removeToken(token, for: cardInfo.card.cardId)
            
            if isRemoved {
                stateUpdateQueue.sync {
                    if let walletModels = self.walletModels {
                        state = .loaded(walletModel: walletModels)
                    }
                }
            }
        }
    }
    
    private func tryMigrateTokens(completion: @escaping (Bool) -> Void) {
        let cardId = cardInfo.card.cardId
        let items = tokenItemsRepository.getItems(for: cardId)
        let itemsWithCustomTokens = items.filter { item in
            return item.tokens.contains(where: { $0.isCustom })
        }
        
        if itemsWithCustomTokens.isEmpty {
            completion(false)
            return
        }
        
        let publishers = itemsWithCustomTokens.flatMap { item in
            item.tokens.map { token in
                tokenListService.checkContractAddress(contractAddress: token.contractAddress, networkId: item.blockchainNetwork.blockchain.id)
                    .replaceError(with: [])
                    .map { [unowned self] models in
                        if let updatedTokem = models.first?.items.compactMap({$0.token}).first {
                            self.tokenItemsRepository.append([updatedTokem], blockchainNetwork: item.blockchainNetwork, for: cardId)
                        }
                    }
                    .eraseToAnyPublisher()
            }
        }
        
        Publishers.MergeMany(publishers)
            .collect(publishers.count)
            .sink {[unowned self] _ in
                self.updateState()
                completion(true)
            } receiveValue: { _ in }
            .store(in: &bag)
    }
    
    func updateCardPinSettings() {
        cardPinSettings.isPin1Default = !cardInfo.card.isAccessCodeSet
        cardInfo.card.isPasscodeSet.map { self.cardPinSettings.isPin2Default = !$0 }
    }
    
    func updateCurrentSecOption() {
        if !(cardPinSettings.isPin1Default ?? true) {
            self.currentSecOption = .accessCode
        } else if !(cardPinSettings.isPin2Default ?? true) {
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
