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
import TangemSdk

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
    
    weak var assembly: Assembly!
    weak var navigation: NavigationCoordinator!
    weak var cardModel: CardViewModel?
    
    @Published var type: TokenType = .blockchain
    @Published var name = ""
    @Published var symbol = ""
    @Published var contractAddress = ""
    @Published var decimals = ""
    @Published var derivationPath = ""
    
    @Published var blockchains: [(String, String)] = []
    @Published var blockchainName: String = ""

    @Published var error: AlertBinder?
    
    private var bag: Set<AnyCancellable> = []
    private var blockchainByName: [String: Blockchain] = [:]
    
    init() {
        $type
            .sink {
                self.updateBlockchains(type: $0)
            }
            .store(in: &bag)
    }
    
    func createToken() {
        guard let cardModel = cardModel else {
            return
        }
        
        UIApplication.shared.endEditing()
        
        guard let blockchain = blockchainByName[blockchainName] else {
            error = TokenCreationErrors.blockchainNotSelected.alertBinder
            return
        }
        
        
        let derivationPath: DerivationPath?
        if !self.derivationPath.isEmpty {
            derivationPath = try? DerivationPath(rawPath: self.derivationPath)
            
            if derivationPath == nil {
                error = TokenCreationErrors.invalidDerivationPath.alertBinder
                return
            }
        } else {
            derivationPath = nil
        }
        
        var itemsToAdd: [TokenItem] = []
        if type == .token {
            guard !name.isEmpty, !symbol.isEmpty, !contractAddress.isEmpty, !decimals.isEmpty else {
                error = TokenCreationErrors.emptyFields.alertBinder
                return
            }

            guard let decimals = Int(decimals) else {
                error = TokenCreationErrors.invalidDecimals.alertBinder
                return
            }
            
            guard blockchain.validate(address: contractAddress) else {
                error = TokenCreationErrors.invalidContractAddress.alertBinder
                return
            }
            
            let token = Token(name: name,
                              symbol: symbol.uppercased(),
                              contractAddress: contractAddress,
                              decimalCount: decimals,
                              blockchain: blockchain)
            itemsToAdd.append(.init(token, derivationPath: derivationPath))
        } else {
            itemsToAdd.append(.init(blockchain, derivationPath: derivationPath))
        }
        
        cardModel.manageTokenItems(add: itemsToAdd, remove: []) { result in
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
            let blockchainsWithTokens = supportedTokenItems.blockchainsWithTokens(isTestnet: cardInfo.isTestnet)
            return blockchains
                .filter {
                    blockchainsWithTokens.contains($0)
                }
        } else {
            return blockchains
        }
    }
}
