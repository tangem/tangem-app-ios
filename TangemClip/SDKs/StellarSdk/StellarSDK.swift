//
//  StellarSDK.swift
//  stellarsdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public class StellarSDK: NSObject {
    
    public var horizonURL: String
    
    public var accounts: AccountService
    public var ledgers: LedgersService
    
    public override init() {
        horizonURL = "https://horizon-testnet.stellar.org"
        
        accounts = AccountService(baseURL: horizonURL)
        ledgers = LedgersService(baseURL: horizonURL)
    }
    
    public init(withHorizonUrl horizonURL:String) {
        self.horizonURL = horizonURL
        
        accounts = AccountService(baseURL: horizonURL)
        ledgers = LedgersService(baseURL: horizonURL)
    }
}
