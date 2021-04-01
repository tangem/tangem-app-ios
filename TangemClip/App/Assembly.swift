//
//  Assembly.swift
//  TangemClip
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdkClips
import BlockchainSdkClips
import Combine

class ServicesAssembly {
    weak var assembly: Assembly!
    
    deinit {
        print("ServicesAssembly deinit")
    }
    
    let logger = Logger()
    lazy var ratesService = CoinMarketCapService(apiKey: keysManager.coinMarketKey)
    lazy var userPrefsService = UserPrefsService()
    lazy var networkService = NetworkService()
    lazy var walletManagerFactory = WalletManagerFactory(config: keysManager.blockchainConfig)
    lazy var imageLoaderService: ImageLoaderService = ImageLoaderService(networkService: networkService)
    lazy var tangemSdk: TangemSdk = .init()
    
    lazy var cardsRepository: CardsRepository = {
        let crepo = CardsRepository()
        crepo.tangemSdk = tangemSdk
        crepo.assembly = assembly
        crepo.delegate = self
        return crepo
    }()
    
    private let keysManager = try! KeysManager()
    
    private lazy var defaultSdkConfig: Config = {
        var config = Config()
        config.logСonfig = Log.Config.custom(logLevel: Log.Level.allCases, loggers: [logger])
        return config
    }()
    
}

extension ServicesAssembly: CardsRepositoryDelegate {
    func onDidScan(_ cardInfo: CardInfo) {
    }
    
    func onWillScan() {
        tangemSdk.config = defaultSdkConfig
    }
}

class Assembly {

    public let services: ServicesAssembly
    private var modelsStorage = [String : Any]()
    
    init() {
        services = ServicesAssembly()
        services.assembly = self
    }
    
    var sdkConfig: Config {
        Config()
    }
    
    func getMainViewModel() -> MainViewModel {
        guard let model: MainViewModel = get() else {
            let mainModel = MainViewModel(cardsRepository: services.cardsRepository, imageLoaderService: services.imageLoaderService)
            store(mainModel)
            return mainModel
        }
        
        return model
    }
    
    // MARK: Card model
    func makeCardModel(from info: CardInfo) -> CardViewModel {
        let vm = CardViewModel(cardInfo: info)
        vm.assembly = self
        vm.tangemSdk = services.tangemSdk
        vm.updateState()
        return vm
    }
    
    // MARK: Wallets
    func makeWalletModels(from info: CardInfo) -> AnyPublisher<[WalletModel], Never> {
        info.card.wallets.publisher
            .removeDuplicates(by: { $0.curve == $1.curve })
            .filter { $0.status == .loaded }
            .compactMap { cardWallet -> [WalletModel]? in
                guard let curve = cardWallet.curve else { return nil }
                
                let blockchains = SupportedBlockchains.blockchains(from: curve, testnet: false)
                let managers = self.services.walletManagerFactory.makeWalletManagers(for: cardWallet, cardId: info.card.cardId!, blockchains: blockchains)
                
                return managers.map {
                    let model = WalletModel(cardWallet: cardWallet, walletManager: $0)
                    model.ratesService = self.services.ratesService
                    return model
                }
            }
            .reduce([], { $0 + $1 })
            .eraseToAnyPublisher()
    }
    
    func updateAppClipCard(with batch: String?) {
        let mainModel: MainViewModel? = get()
        mainModel?.updateCardBatch(batch)
    }
    
    func updateCardUrl(_ url: String) {
        let mainModel: MainViewModel? = get()
        mainModel?.cardUrl = url
    }
    
    private func store<T>(_ object: T) {
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
        
        // Bitcoin old test card
        let testCardScan = scanResult(for: Card.testCard, assembly: assembly)
        
        // Which card data should be displayed in preview?
        assembly.services.cardsRepository.lastScanResult = testCardScan
        return assembly
    }()
    
    private static func scanResult(for card: Card, assembly: Assembly, twinCardInfo: TwinCardInfo? = nil) -> ScanResult {
        let ci = CardInfo(card: card,
                          artworkInfo: nil,
                          twinCardInfo: twinCardInfo)
        let vm = assembly.makeCardModel(from: ci)
        let scanResult = ScanResult.card(model: vm)
        assembly.services.cardsRepository.cards[card.cardId!] = scanResult
        return scanResult
    }
}
