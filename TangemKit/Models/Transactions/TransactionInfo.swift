//
//  TransactionInfo.swift
//  TangemKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Smart Cash AG. All rights reserved.
//

import Foundation

class TransactionInfo: NSObject, NSCoding {
    
    var transactionid: String = ""
    var cardId: String = ""
    private var expirationTimeInterval: TimeInterval
    
    enum CodingKeys: String, CodingKey {
        case transactionid
        case cardId
        case expirationTimeInterval
    }
    
    var isExpired: Bool {
        return expirationTimeInterval < Date().timeIntervalSince1970
    }
    
    init(transactionid: String, cardId: String, expireDate: Date) {
        self.transactionid = transactionid
        self.expirationTimeInterval = expireDate.timeIntervalSince1970
        self.cardId = cardId
    }
    
    required init?(coder aDecoder: NSCoder) {
        if let transactionid = aDecoder.decodeObject(forKey: CodingKeys.transactionid.rawValue) as? String {
            self.transactionid = transactionid
        } 
        if let cardId = aDecoder.decodeObject(forKey: CodingKeys.cardId.rawValue) as? String {
            self.cardId = cardId
        }
        
        self.expirationTimeInterval = aDecoder.decodeDouble(forKey: CodingKeys.expirationTimeInterval.rawValue)
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(transactionid, forKey: CodingKeys.transactionid.rawValue)
        aCoder.encode(cardId, forKey: CodingKeys.cardId.rawValue)
        aCoder.encode(expirationTimeInterval, forKey: CodingKeys.expirationTimeInterval.rawValue)
    }
    
}
