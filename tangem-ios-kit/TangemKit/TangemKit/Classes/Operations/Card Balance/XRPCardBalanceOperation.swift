//
//  ETHCardBalanceOperation.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Smart Cash AG. All rights reserved.
//

import Foundation
import Moya
import SwiftyJSON

class XRPCardBalanceOperation: BaseCardBalanceOperation {
    
    let provider = MoyaProvider<XrpTarget>(plugins: [NetworkLoggerPlugin(verbose: true)])
    
    override func handleMarketInfoLoaded(priceUSD: Double) {
        guard !isCancelled else {
            return
        }
        
        card.mult = priceUSD
        
        provider.request(.accountInfo(account: card.address)) { [weak self] result in
            switch result {
            case .success(let response):
                guard let xrpResult = (try? response.map(XrpResponse.self))?.result else {
                    self?.card.mult = 0
                    self?.failOperationWith(error: Localizations.loadedWalletErrorObtainingBlockchainData)
                    return
                }
                
                if let code = xrpResult.error_code, code == 19 {
                    self?.failOperationWith(error: Localizations.loadMoreXrpToCreateAccount, title: Localizations.accountNotFound)
                    return
                }
                
                guard let accountResponse = xrpResult.account_data,
                    let balanceString = accountResponse.balance,
                    let balance = UInt64(balanceString) else {
                        self?.card.mult = 0
                        self?.failOperationWith(error: Localizations.loadedWalletErrorObtainingBlockchainData)
                        return
                }
                
                (self?.card.cardEngine as? RippleEngine)?.accountInfo = accountResponse
                
                let walletValue = NSDecimalNumber(value: balance).dividing(by: NSDecimalNumber(value: 1).multiplying(byPowerOf10: Blockchain.ripple.decimalCount)).stringValue
                
                (self?.card.cardEngine as? RippleEngine)?.confirmedBalance =
                "\(walletValue)"
                
                self?.handleBalanceLoaded(balanceValue: walletValue)
            case .failure(let error):
                self?.card.mult = 0
                self?.failOperationWith(error: error)
            }
        }
        
        
        //        let operation = RippleNetworkBalanceOperation(address: card.address) { [weak self] (result) in
        //            switch result {
        //            case .success(let value):
        //                self?.handleBalanceLoaded(balanceValue: value)
        //            case .failure(let error):
        //                self?.card.mult = 0
        //                self?.failOperationWith(error: error)
        //            }
        //        }
        //        operationQueue.addOperation(operation)
    }
    
    func handleBalanceLoaded(balanceValue: String) {
        guard !isCancelled else {
            return
        }
        
        card.walletValue = balanceValue
        
        provider.request(.reserve) { [weak self] result in
            switch result {
            case .success(let response):
                guard let xrpResult = (try? response.map(XrpResponse.self))?.result,
                    let reserveBase = xrpResult.state?.validated_ledger?.reserve_base else {
                        self?.card.mult = 0
                        self?.failOperationWith(error: Localizations.loadedWalletErrorObtainingBlockchainData)
                        return
                }
                
                let reserveValue = NSDecimalNumber(value: reserveBase).dividing(by: NSDecimalNumber(value: 1).multiplying(byPowerOf10: Blockchain.ripple.decimalCount))
                let rounded = (reserveValue as Decimal).rounded(blockchain: .ripple)
                
                self?.handleReserveLoaded(reserve: "\(rounded)")
            case .failure(let error):
                self?.failOperationWith(error: error)
            }
        }
        
        //        let operation = RippleNetworkReserveOperation { [weak self] (result) in
        //            switch result {
        //            case .success(let value):
        //                self?.handleReserveLoaded(reserve: value)
        //            case .failure(let error):
        //                self?.failOperationWith(error: error)
        //            }
        //        }
        //        operationQueue.addOperation(operation)
    }
    
    func handleReserveLoaded(reserve: String) {
        guard !isCancelled else {
            return
        }
        
        if let xrpEngine = card.cardEngine as? RippleEngine {
            xrpEngine.walletReserve = reserve
        }
        
        guard let balanceValue = Double(card.walletValue), let reserveValue = Double(reserve) else {
            assertionFailure()
            completeOperation()
            return
        }
        
        
        let walletValue = NSDecimalNumber(value: balanceValue).subtracting(NSDecimalNumber(value: reserveValue))
        let rounded = (walletValue as Decimal).rounded(blockchain: .ripple)
        card.walletValue =  "\(rounded)"
        
        loadUnconfirmed()
    }
    
    
    func loadUnconfirmed() {
        provider.request(.unconfirmed(account: card.address)) { [weak self] result in
            switch result {
            case .success(let response):
                guard let xrpResult = (try? response.map(XrpResponse.self))?.result,
                    let unconfirmedBalanceString = xrpResult.account_data?.balance,
                    let unconfirmedBalance = UInt64(unconfirmedBalanceString) else {
                        self?.card.mult = 0
                        self?.failOperationWith(error: Localizations.loadedWalletErrorObtainingBlockchainData)
                        return
                }
                
                let unconfirmedValue = NSDecimalNumber(value: unconfirmedBalance).dividing(by: NSDecimalNumber(value: 1).multiplying(byPowerOf10: Blockchain.ripple.decimalCount)).stringValue
                
                (self?.card.cardEngine as? RippleEngine)?.unconfirmedBalance =
                "\(unconfirmedValue)"
                
                self?.completeOperation()
            case .failure(let error):
                self?.failOperationWith(error: error)
            }
        }
    }
}
