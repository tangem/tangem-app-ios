//
//  AddCustomTokenViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import struct TangemSdk.DerivationPath
import enum TangemSdk.TangemSdkError

class AddCustomTokenViewModel: ViewModel, ObservableObject {
    private enum TokenCreationErrors: LocalizedError {
        case blockchainNotSelected
        case emptyFields
        case invalidDecimals
        case invalidContractAddress
        case invalidDerivationPath
        
        var errorDescription: String? {
            switch self {
            case .blockchainNotSelected:
                return "custom_token_creation_error_network_not_selected".localized
            case .emptyFields:
                return "custom_token_creation_error_empty_fields".localized
            case .invalidDecimals:
                return "custom_token_creation_error_wrong_decimals".localized
            case .invalidContractAddress:
                return "custom_token_creation_error_invalid_contract_address".localized
            case .invalidDerivationPath:
                return "custom_token_creation_error_invalid_derivation_path".localized
            }
        }
    }
    
    private enum TokenSearchError: LocalizedError {
        case alreadyAdded
        case failedToFindToken
        
        var preventsFromAdding: Bool {
            switch self {
            case .alreadyAdded:
                return true
            case .failedToFindToken:
                return false
            }
        }
        
        var errorDescription: String? {
            switch self {
            case .failedToFindToken:
                return "custom_token_validation_error_not_found".localized
            case .alreadyAdded:
                return "custom_token_validation_error_already_added".localized
            }
        }
        
        var appWarning: AppWarning {
            return AppWarning(title: "common_warning".localized, message: errorDescription ?? "", priority: .warning)
        }
    }
    
    weak var assembly: Assembly!
    weak var navigation: NavigationCoordinator!
    weak var cardModel: CardViewModel!
    weak var tokenListService: TokenListService!
    
    @Published var name = ""
    @Published var symbol = ""
    @Published var contractAddress = ""
    @Published var decimals = ""
    
    @Published var blockchains: [(String, String)] = []
    @Published var blockchainName: String = ""
    @Published var blockchainEnabled: Bool = true
    
    @Published var derivationPath = ""
    @Published var derivationPaths: [(String, String)] = []
    
    @Published var error: AlertBinder?
    
    @Published var warningContainer = WarningsContainer()
    @Published var addButtonDisabled = false
    @Published var isLoading = false
    
    @Published private(set) var foundStandardToken: TokenItem?

    private var bag: Set<AnyCancellable> = []
    private var blockchainByName: [String: Blockchain] = [:]
    private var blockchainsWithTokens: Set<Blockchain>?
    private var cachedTokens: [Blockchain: [Token]] = [:]
    
    init() {
        Publishers.CombineLatest3($blockchainName, $contractAddress, $derivationPath)
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .setFailureType(to: Error.self)
            .flatMap { (blockchainName, contractAddress, derivationPath) -> AnyPublisher<[CurrencyModel], Error> in
                self.isLoading = true
                
                return self.validateToken(blockchainName: blockchainName, contractAddress: contractAddress, derivationPath: derivationPath)
                    .catch { [unowned self] error -> AnyPublisher<[CurrencyModel], Error> in
                        self.isLoading = false
                        self.foundStandardToken = nil
                        self.updateBlockchains(self.getBlockchains(withTokenSupport: true))
                        
                        let tokenSearchError = error as? TokenSearchError
                        self.addButtonDisabled = tokenSearchError?.preventsFromAdding ?? false
                        self.warningContainer.removeAll()
                        if let tokenSearchError = tokenSearchError {
                            self.warningContainer.add(tokenSearchError.appWarning)
                        }
                        
                        return Empty(completeImmediately: false).setFailureType(to: Error.self).eraseToAnyPublisher()
                    }
                    .eraseToAnyPublisher()
            }
            .sink { _ in
                
            } receiveValue: { [unowned self] currencyModels in
                self.warningContainer.removeAll()
                self.addButtonDisabled = false
                self.isLoading = false
                
                let currencyModelBlockchains = currencyModels.reduce(Set<Blockchain>()) { partialResult, currencyModel in
                    partialResult.union(currencyModel.items.map { $0.blockchain })
                }

                let blockchains: Set<Blockchain>
                if !currencyModelBlockchains.isEmpty {
                    blockchains = currencyModelBlockchains
                } else {
                    blockchains = getBlockchains(withTokenSupport: true)
                }
                self.updateBlockchains(blockchains)
                
                let firstTokenItem = currencyModels.first?.items.first
                
                if currencyModels.count == 1 {
                    self.foundStandardToken = firstTokenItem
                } else {
                    self.foundStandardToken = nil
                }
                
                if let token = firstTokenItem?.token {
                    self.decimals = "\(token.decimalCount)"
                    self.symbol = token.symbol
                    self.name = token.name
                }
            }
            .store(in: &bag)
    }
    
    func createToken() {
        UIApplication.shared.endEditing()
        
        let tokenItem: TokenItem
        if let foundStandardToken = self.foundStandardToken {
            tokenItem = foundStandardToken
        } else {
            switch enteredTokenItem() {
            case .failure(let error):
                self.error = error.alertBinder
                return
            case .success(let enteredTokenItem):
                tokenItem = enteredTokenItem
                
            }
        }

        let amountType: Amount.AmountType
        if let token = tokenItem.token {
            amountType = .token(value: token)
        } else {
            amountType = .coin
        }
        let blockchainNetwork = BlockchainNetwork(tokenItem.blockchain, derivationPath: nil)
        #warning("[REDACTED_TODO_COMMENT]")

        cardModel.add(items: [(amountType, blockchainNetwork)]) { result in
            switch result {
            case .success:
                self.navigation.mainToCustomToken = false
                self.navigation.mainToAddTokens = false
            case .failure(let error):
                if case TangemSdkError.userCancelled = error {
                    return
                }

                self.error = error.alertBinder
            }
        }
    }
    
    func onAppear() {
        updateBlockchains(getBlockchains(withTokenSupport: true))
        updateDerivationPaths()
    }
    
    func onDisappear() {
        blockchainName = ""
        name = ""
        symbol = ""
        contractAddress = ""
        decimals = ""
        derivationPath = ""
    }
    
    private func updateBlockchains(_ blockchains: Set<Blockchain>) {
        let defaultItem = ("custom_token_network_input_not_selected".localized, "")
        self.blockchains = [defaultItem] + blockchains.sorted {
            $0.displayName < $1.displayName
        }.map {
            ($0.displayName, $0.codingKey)
        }
        self.blockchainByName = Dictionary(uniqueKeysWithValues: blockchains.map {
            ($0.codingKey, $0)
        })
        self.blockchainEnabled = blockchains.count > 1
        
        
        let newBlockchainName: String?
        if blockchains.count == 1, let firstBlockchain = blockchains.first {
            newBlockchainName = firstBlockchain.codingKey
        } else if blockchainByName[blockchainName] == nil {
            newBlockchainName = ""
        } else {
            newBlockchainName = nil
        }
        
        if let newBlockchainName = newBlockchainName, newBlockchainName != self.blockchainName {
            self.blockchainName = newBlockchainName
        }
    }
    
    private func getBlockchains(withTokenSupport: Bool) -> Set<Blockchain> {
        let cardInfo = cardModel.cardInfo
        
        let supportedTokenItems = SupportedTokenItems()
        let blockchains = supportedTokenItems.blockchains(for: cardInfo.card.walletCurves, isTestnet: cardInfo.isTestnet)
        
        if withTokenSupport {
            if self.blockchainsWithTokens == nil {
                self.blockchainsWithTokens = supportedTokenItems.blockchainsWithTokens(isTestnet: cardInfo.isTestnet)
            }
            
            return blockchains
                .filter {
                    self.blockchainsWithTokens?.contains($0) ?? false
                }
        } else {
            return blockchains
        }
    }
    
    private func updateDerivationPaths() {
        let derivationStyle = cardModel.cardInfo.card.derivationStyle
        
        let defaultItem = ("custom_token_derivation_path_default".localized, "")
        self.derivationPaths = [defaultItem] + getBlockchains(withTokenSupport: true)
            .map {
                let derivationPath = $0.derivationPath(for: derivationStyle)?.rawPath ?? ""
                let description = "\($0.displayName) (\(derivationPath))"
                return (description, derivationPath)
            }
            .sorted {
                $0.0 < $1.0
            }
    }
    
    private func enteredTokenItem() -> Result<TokenItem, Error> {
        guard let blockchain = blockchainByName[blockchainName] else {
            return .failure(TokenCreationErrors.blockchainNotSelected)
        }
        
        let derivationPath: DerivationPath?
        if !self.derivationPath.isEmpty {
            derivationPath = try? DerivationPath(rawPath: self.derivationPath)
            
            if derivationPath == nil {
                return .failure(TokenCreationErrors.invalidDerivationPath)
            }
        } else {
            derivationPath = nil
        }
        
        if contractAddress.isEmpty && name.isEmpty && symbol.isEmpty && decimals.isEmpty {
            return .success(.blockchain(blockchain))
        } else {
            guard blockchain.validate(address: contractAddress) else {
                return .failure(TokenCreationErrors.invalidContractAddress)
            }
            
            guard !name.isEmpty, !symbol.isEmpty, !decimals.isEmpty else {
                return .failure(TokenCreationErrors.emptyFields)
            }
            
            guard let decimals = Int(decimals) else {
                return .failure(TokenCreationErrors.invalidDecimals)
            }
            
            let token = Token(
                name: name,
                symbol: symbol.uppercased(),
                contractAddress: contractAddress,
                decimalCount: decimals
            )
            
            return .success(.token(token, blockchain))
        }
    }
    
    private func validateToken(blockchainName: String, contractAddress: String, derivationPath: String) -> AnyPublisher<[CurrencyModel], Error> {
        let derivationStyle = cardModel.cardInfo.card.derivationStyle
        let cardId = cardModel.cardInfo.card.cardId
        
        let blockchain = blockchainByName[blockchainName]
        
        let cardTokenItems = cardModel.tokenItemsRepository.getItems(for: cardId)
        let checkingContractAddress = !contractAddress.isEmpty
        let derivationPath = (try? DerivationPath(rawPath: derivationPath)) ?? blockchain?.derivationPath(for: derivationStyle)
        
        if let blockchain = blockchain {
            let blockchainNetwork = BlockchainNetwork(blockchain, derivationPath: derivationPath)
            
            if let networkItem = cardTokenItems.first(where: { $0.blockchainNetwork == blockchainNetwork }) {
                if !checkingContractAddress {
                    return .anyFail(error: TokenSearchError.alreadyAdded)
                }
                
                if networkItem.tokens.contains(where: { $0.contractAddress == contractAddress }) {
                    return .anyFail(error: TokenSearchError.alreadyAdded)
                }
            }
        }
        
        guard !contractAddress.isEmpty else {
            return Just([])
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
      
        return findToken(contractAddress: contractAddress, blockchain: blockchain, derivationPath: derivationPath)
    }
    
    private func findToken(contractAddress: String, blockchain: Blockchain?, derivationPath: DerivationPath?) -> AnyPublisher<[CurrencyModel], Error> {
        return tokenListService
            .checkContractAddress(contractAddress: contractAddress, networkId: nil)
            .tryMap { currencyModels in
                guard
                    !currencyModels.isEmpty
                else {
                    throw TokenSearchError.failedToFindToken
                }
                
                return currencyModels
            }
            .eraseToAnyPublisher()
    }
}


#warning("[REDACTED_TODO_COMMENT]")
#warning("[REDACTED_TODO_COMMENT]")
#warning("[REDACTED_TODO_COMMENT]")
#warning("[REDACTED_TODO_COMMENT]")
#warning("[REDACTED_TODO_COMMENT]")

fileprivate extension Blockchain {
    var networkId: String {
        switch self {
        case .bitcoin: return "bitcoin"
        case .stellar: return "stellar"
        case .ethereum: return "ethereum"
        case .litecoin: return "litecoin"
        case .rsk: return "rootstock"
        case .bitcoinCash: return "bitcoincash"
        case .binance: return "binancecoin"
        case .cardano: return "cardano"
        case .xrp: return "ripple"
        case .ducatus: return "ducatus"
        case .tezos: return "tezos"
        case .dogecoin: return "dogecoin"
        case .bsc: return "binance-smart-chain"
        case .polygon: return "matic-network"
        case .avalanche: return "avalanche-2"
        case .solana: return "solana"
        case .fantom: return "fantom"
        case .polkadot: return "polkadot"
        case .kusama: return "kusama"
        }
    }
}
