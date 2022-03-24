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
    private enum TokenCreationErrors: LocalizedError {
        case blockchainNotSelected
        case emptyFields
        case invalidDecimals
        case invalidContractAddress
        
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
            }
        }
    }
    
    weak var assembly: Assembly!
    weak var navigation: NavigationCoordinator!
    weak var cardModel: CardViewModel?
    
    @Published var name = ""
    @Published var symbol = ""
    @Published var contractAddress = ""
    @Published var decimals = ""
    
    @Published var blockchains: [(String, String)] = []
    @Published var blockchainName: String = ""

    @Published var error: AlertBinder?
    
    private var bag: Set<AnyCancellable> = []
    private var blockchainByName: [String: Blockchain] = [:]
    
    init() {
        
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
        
        let token = Token(
            name: name,
            symbol: symbol.uppercased(),
            contractAddress: contractAddress,
            decimalCount: decimals,
            blockchain: blockchain
        )

        cardModel.addTokenItems([.token(token)]) { result in
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
        updateBlockchains()
    }
    
    func onDisappear() {
        blockchainName = ""
        name = ""
        symbol = ""
        contractAddress = ""
        decimals = ""
    }
    
    private func updateBlockchains() {
        let blockchainsWithTokens = self.blockchainsWithTokens()
        
        self.blockchains = blockchainsWithTokens.map {
            ($0.displayName, $0.codingKey)
        }
        self.blockchainByName = Dictionary(uniqueKeysWithValues: blockchainsWithTokens.map {
            ($0.codingKey, $0)
        })
    }
    
    private func blockchainsWithTokens() -> [Blockchain] {
        guard let cardInfo = cardModel?.cardInfo else {
            return []
        }
        
        let supportedTokenItems = SupportedTokenItems()
        let blockchains = supportedTokenItems.blockchains(for: cardInfo.card.walletCurves, isTestnet: cardInfo.isTestnet)
        
        return blockchains.filter {
            supportedTokenItems.hasTokens(for: $0)
        }
        .sorted {
            $0.displayName < $1.displayName
        }
    }
}
