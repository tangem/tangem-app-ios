//
//  SignatureProvider.swift
//  TangemKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Smart Cash AG. All rights reserved.
//

import Foundation

public protocol CoinProvider {
    var hasPendingTransactions: Bool {get}
    var coinTraitCollection: CoinTrait {get}
    func getHashForSignature(amount: String, fee: String, includeFee: Bool, targetAddress: String) -> Data?
    func sendToBlockchain(signFromCard: [UInt8], completion: @escaping (Bool) -> Void)
    func getFee(targetAddress: String, amount: String, completion: @escaping  ((min: String, normal: String, max: String)?)->Void)
    func validate(address: String) -> Bool
}

public protocol CoinProviderAsync {
    func getHashForSignature(amount: String, fee: String, includeFee: Bool, targetAddress: String, completion: @escaping (Data?) -> Void)
}

public struct CoinTrait: OptionSet {
    public let rawValue: Int
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public static let allowsFeeSelector = CoinTrait(rawValue: 1 << 0)
    public static let allowsFeeInclude = CoinTrait(rawValue: 1 << 1)
    
    static let all: CoinTrait = [.allowsFeeInclude, .allowsFeeSelector]
}
