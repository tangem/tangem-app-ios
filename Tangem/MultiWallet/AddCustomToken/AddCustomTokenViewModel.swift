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
    enum TokenType: Hashable {
        case blockchain
        case token
    }
    
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
                
                
                #warning("l10n")
                
                
                return "Note that tokens can be created by anyone. Be aware of adding scam tokens, they can cost nothing."
            case .alreadyAdded:
                

                #warning("l10n")


                return "This token/network has already been added to your list"
            }
        }
    }
    
    weak var assembly: Assembly!
    weak var navigation: NavigationCoordinator!
    weak var cardModel: CardViewModel?
    weak var tokenListService: TokenListService!
    
    @Published var type: TokenType = .blockchain
    @Published var name = ""
    @Published var symbol = ""
    @Published var contractAddress = ""
    @Published var decimals = ""
    @Published var derivationPath = ""
    
    @Published var blockchains: [(String, String)] = []
    @Published var blockchainName: String = ""

    @Published var error: AlertBinder?
    
    @Published var warning: String?
    @Published var addButtonDisabled = false
    @Published var isLoading = false
    
    private var bag: Set<AnyCancellable> = []
    private var blockchainByName: [String: Blockchain] = [:]
    private var blockchainsWithTokens: Set<Blockchain>?
    private var cachedTokens: [Blockchain: [Token]] = [:]
    private var foundStandardToken: TokenItem?
    
    init() {
        $type
            .sink {
                self.updateBlockchains(type: $0)
            }
            .store(in: &bag)
        
        Publishers.CombineLatest4($type, $blockchainName, $contractAddress, $derivationPath)
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .setFailureType(to: Error.self)
            .flatMap { (type, blockchainName, contractAddress, derivationPath) -> AnyPublisher<TokenItem, Error> in
                self.isLoading = true
                
                return self.validateToken(type: type, blockchainName: blockchainName, contractAddress: contractAddress, derivationPath: derivationPath)
                    .catch { [unowned self] error -> AnyPublisher<TokenItem, Error> in
                        self.isLoading = false
                        self.foundStandardToken = nil
                        
                        let tokenSearchError = error as? TokenSearchError
                        self.addButtonDisabled = tokenSearchError?.preventsFromAdding ?? false
                        self.warning = tokenSearchError?.errorDescription
                        
                        return Empty(completeImmediately: false).setFailureType(to: Error.self).eraseToAnyPublisher()
                    }
                    .eraseToAnyPublisher()
            }
            .sink { _ in
                
            } receiveValue: { [unowned self] token in
                self.warning = nil
                self.addButtonDisabled = false
                self.isLoading = false
                self.foundStandardToken = token
                
                if let token = foundStandardToken?.token {
                    self.decimals = "\(token.decimalCount)"
                    self.symbol = token.symbol
                    self.name = token.name
                }
            }
            .store(in: &bag)
    }
    
    func createToken() {
        guard let cardModel = cardModel else {
            return
        }
        
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
        
        cardModel.manageTokenItems(add: [tokenItem], remove: []) { result in
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
        updateBlockchains(type: type)
    }
    
    func onDisappear() {
        blockchainName = ""
        name = ""
        symbol = ""
        contractAddress = ""
        decimals = ""
        derivationPath = ""
    }
    
    private func updateBlockchains(type: TokenType) {
        let blockchains = getBlockchains(withTokenSupport: type == .token)
        
        self.blockchains = blockchains.map {
            ($0.displayName, $0.codingKey)
        }
        self.blockchainByName = Dictionary(uniqueKeysWithValues: blockchains.map {
            ($0.codingKey, $0)
        })
        
        if blockchainByName[blockchainName] == nil {
            self.blockchainName = ""
        }
    }
    
    private func getBlockchains(withTokenSupport: Bool) -> [Blockchain] {
        guard let cardInfo = cardModel?.cardInfo else {
            return []
        }
        
        let supportedTokenItems = SupportedTokenItems()
        let blockchains = supportedTokenItems
            .blockchains(for: cardInfo.card.walletCurves, isTestnet: cardInfo.isTestnet)
            .sorted {
                $0.displayName < $1.displayName
            }
        
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
        
        if type == .token {
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
                decimalCount: decimals,
                blockchain: blockchain
            )
            
            return .success(.init(token, derivationPath: derivationPath, isCustom: true))
        } else {
            return .success(.init(blockchain, derivationPath: derivationPath))
        }
    }
    
    private func validateToken(type: TokenType, blockchainName: String, contractAddress: String, derivationPath: String) -> AnyPublisher<TokenItem, Error> {
        guard let blockchain = blockchainByName[blockchainName] else {
            return .anyFail(error: TokenCreationErrors.blockchainNotSelected)
        }
        
        guard !contractAddress.isEmpty else {
            return .anyFail(error: TokenCreationErrors.invalidContractAddress)
        }
        
        let cardTokenItems = cardModel?.tokenItemsRepository.getItems(for: cardModel?.cardInfo.card.cardId ?? "") ?? []
        let checkingContractAddress = (type == .token)
        let derivationPath = (try? DerivationPath(rawPath: derivationPath)) ?? blockchain.derivationPath
        
        if cardTokenItems.contains(where: {
            ($0.contractAddress == contractAddress || !checkingContractAddress) &&
            $0.blockchain == blockchain &&
            $0.derivationPath == derivationPath
        })
        {
            return .anyFail(error: TokenSearchError.alreadyAdded)
        }
        
        switch type {
        case .blockchain:
            return Just(TokenItem(blockchain, derivationPath: derivationPath, isCustom: false))
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        case .token:
            return findToken(contractAddress: contractAddress, blockchain: blockchain, derivationPath: derivationPath)
        }
    }
    
    private func findToken(contractAddress: String, blockchain: Blockchain, derivationPath: DerivationPath?) -> AnyPublisher<TokenItem, Error> {
        return tokenListService
            .checkContractAddress(contractAddress: contractAddress, networkId: blockchain.networkId)
            .tryMap { tokenItem in
                guard
                    let tokenItem = tokenItem,
                    let token = tokenItem.token
                else {
                    throw TokenSearchError.failedToFindToken
                }
                
                let isCustom = derivationPath == token.blockchain.derivationPath
                return TokenItem(token, id: tokenItem.id, derivationPath: derivationPath, isCustom: isCustom)
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
