//
//  CardanoPendingTransactionsStorage.swift
//  TangemKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Smart Cash AG. All rights reserved.
//

import Foundation

class CardanoPendingTransactionsStorage {
    
    private static var kPendingTransactionsFilePath: String {
        let manager = FileManager.default
        let url = manager.urls(for: .documentDirectory, in: .userDomainMask).first
        return url!.appendingPathComponent("CardanoPendingTransactions").path
    }
    
    static let shared = CardanoPendingTransactionsStorage()
    
    private var pendingTransactions: [TransactionInfo]
    
    init() {
        if let pendingTransactions = NSKeyedUnarchiver.unarchiveObject(withFile: CardanoPendingTransactionsStorage.kPendingTransactionsFilePath) as? [TransactionInfo] {
            self.pendingTransactions = pendingTransactions
        } else {
            self.pendingTransactions = []
        }
    }
    
    private func saveToDisk() {
        NSKeyedArchiver.archiveRootObject(pendingTransactions, toFile: CardanoPendingTransactionsStorage.kPendingTransactionsFilePath)
    }
    
    private func pendingTransactionsForCardId(_ cardId: String) -> [TransactionInfo] {
        return pendingTransactions.filter({ $0.cardId == cardId })
    }
    
    // MARK: Public methods
    
    public func hasPendingTransactions(_ card: CardViewModel) -> Bool {
        return !pendingTransactionsForCardId(card.cardID).isEmpty
    }
    
    public func append(transactionId: String, card: CardViewModel, expirationTimeoutSeconds: Int) {
        let expirationDate = Date().addingTimeInterval(TimeInterval(expirationTimeoutSeconds))
        let transactionInfo = TransactionInfo(transactionid: transactionId, cardId: card.cardID, expireDate: expirationDate)
        
        pendingTransactions.append(transactionInfo)
        
        saveToDisk()
    }
    
    public func cleanup(existingTransactionsIds: [String], card: CardViewModel) {
        pendingTransactions = pendingTransactions.filter({
            guard !$0.isExpired else {
                return false
            }
            
            guard $0.cardId == card.cardID else {
                return true
            }
            
            return !existingTransactionsIds.contains($0.transactionid) 
        }) 
        
        saveToDisk()
    }
    
    public func purge() {
        pendingTransactions = []
        saveToDisk()
    }
    
}
