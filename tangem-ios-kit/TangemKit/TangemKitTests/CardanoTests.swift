//
//  CardanoTests.swift
//  TangemKitTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Smart Cash AG. All rights reserved.
//

import XCTest
import SwiftCBOR
import GBAsyncOperation

@testable import TangemKit

class CardanoTests: XCTestCase {
    
    var currentValidationBlock: ((CardViewModel) -> Void)?
    var session: TangemSession?
    var currentExpectation: XCTestExpectation?
    let operationQueue = OperationQueue()

    func testBuildCardanoTransaction() {
        let ethalonTXHash = [1, 26, 45, -106, 74, 9, 88, 32, -24, -19, -20, 16, -114, 12, -111, 53, -16, -28, 1, -4, -23, 116, 99, 41, 63, 95, -82, 79, -83, 80, 67, 123, -7, 123, -25, 96, 40, 25, -5, 102].bytes
        
        
        let ethalonTXBody = [-125, -97, -126, 0, -40, 24, 88, 36, -126, 88, 32, 97, -97, -47, 17, 67, 17, 48, 31, 6, 101, -18, 79, -108, 102, 105, -87, -112, 56, 102, 7, 42, 66, -34, 7, -20, 47, 25, -114, 12, -114, 86, 71, 0, -1, -97, -126, -126, -40, 24, 88, 33, -125, 88, 28, -113, 107, -91, 83, 97, 15, -22, -37, 95, -49, -124, -31, -40, -93, 90, -23, 92, 66, 14, 28, 115, 85, -125, 3, 12, -14, 21, 121, -96, 0, 26, 115, -70, -107, -52, 0, -126, -126, -40, 24, 88, 33, -125, 88, 28, 29, -118, -114, -18, -9, -85, 71, 52, -53, -64, -27, -9, 18, 42, -84, 24, 22, 102, 6, -121, -74, 34, -99, -120, -124, 38, 60, 86, -96, 0, 26, 101, -102, 107, -26, 26, 0, 8, -32, 35, -1, -96].bytes
        
        let walletAddress = "Ae2tdPwUPEYykj3kHNLjrHd6jisMhAdDDRbobq7zhL7koTipv1DfPHn7rN1"
        let unspentOutputs = ["619fd1114311301f0665ee4f946669a9903866072a42de07ec2f198e0c8e5647"]
        let targetAddress = "Ae2tdPwUPEZB7miP6R9CxCeL23h6wQPc2nrpfHj7NG4xLpc1z9vb29odo7y"
        
        let dummyFee = NSDecimalNumber(0.2000000).multiplying(byPowerOf10: Int16(6), withBehavior: nil).stringValue
        let transaction = CardanoTransaction(unspentOutputs: unspentOutputs, 
                                             cardWalletAddress: walletAddress, 
                                             targetAddress: targetAddress, 
                                             amount: "200000",
                                             walletBalance: "781667",
                                             feeValue: dummyFee,
                                             isIncludeFee: true)


        XCTAssertEqual(transaction.transactionBody!, ethalonTXBody)
        XCTAssertEqual(ethalonTXHash, transaction.dataToSign!)
    }
    
    func testCardanoTxForSend() {
        let ethalonTxForSend = [-126, -125, -97, -126, 0, -40, 24, 88, 36, -126, 88, 32, 97, -97, -47, 17, 67, 17, 48, 31, 6, 101, -18, 79, -108, 102, 105, -87, -112, 56, 102, 7, 42, 66, -34, 7, -20, 47, 25, -114, 12, -114, 86, 71, 0, -1, -97, -126, -126, -40, 24, 88, 33, -125, 88, 28, -113, 107, -91, 83, 97, 15, -22, -37, 95, -49, -124, -31, -40, -93, 90, -23, 92, 66, 14, 28, 115, 85, -125, 3, 12, -14, 21, 121, -96, 0, 26, 115, -70, -107, -52, 0, -126, -126, -40, 24, 88, 33, -125, 88, 28, 29, -118, -114, -18, -9, -85, 71, 52, -53, -64, -27, -9, 18, 42, -84, 24, 22, 102, 6, -121, -74, 34, -99, -120, -124, 38, 60, 86, -96, 0, 26, 101, -102, 107, -26, 26, 0, 8, -32, 35, -1, -96, -127, -126, 0, -40, 24, 88, -123, -126, 88, 64, -121, -128, -5, -102, -89, 89, -126, -17, -23, -93, -94, -93, 60, -107, -120, 65, 113, -85, -112, -96, -114, -74, 34, 12, -120, -16, 96, -123, 49, 43, 19, 94, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 88, 64, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0].bytes
        
        
        let walletAddress = "Ae2tdPwUPEYykj3kHNLjrHd6jisMhAdDDRbobq7zhL7koTipv1DfPHn7rN1"
        let unspentOutputs = ["619fd1114311301f0665ee4f946669a9903866072a42de07ec2f198e0c8e5647"]
        let targetAddress = "Ae2tdPwUPEZB7miP6R9CxCeL23h6wQPc2nrpfHj7NG4xLpc1z9vb29odo7y"
        
        let dummyFee = NSDecimalNumber(0.2000000).multiplying(byPowerOf10: Int16(6), withBehavior: nil).stringValue
        let transaction = CardanoTransaction(unspentOutputs: unspentOutputs,
                                             cardWalletAddress: walletAddress,
                                             targetAddress: targetAddress,
                                             amount: "200000",
                                             walletBalance: "781667",
                                             feeValue: dummyFee,
                                             isIncludeFee: true)
        let card = CardViewModel()
        card.walletPublicKey = "8780FB9AA75982EFE9A3A2A33C95884171AB90A08EB6220C88F06085312B135E"
        card.walletPublicKeyBytesArray = Array(card.walletPublicKey.hexData()!)
        let engine = CardanoEngine(card: card)
        engine.unspentOutputs =  ["619fd1114311301f0665ee4f946669a9903866072a42de07ec2f198e0c8e5647"]
        engine.transaction = transaction
        engine.walletAddress = "Ae2tdPwUPEYykj3kHNLjrHd6jisMhAdDDRbobq7zhL7koTipv1DfPHn7rN1"
        card.cardEngine = engine
        
        let dummySignFromCard: [UInt8] = Array(repeating: 0, count: 64)
        let txForSend = engine.buildTxForSend(signFromCard: dummySignFromCard)!
        
        XCTAssertEqual(txForSend, ethalonTxForSend)
    }
    
    func testSendCardanoTransaction() {
        let expectation = XCTestExpectation(description: "Card values parsing check")
        
        validateCardWith(payload: Data(TestData.cardano.rawValue.asciiHexToData()!)) { (card) in
            
            guard let cardanoEngine = card.cardEngine as? CardanoEngine else {
                return
            }
            
            cardanoEngine.unspentOutputs = ["6f5d271bb154628cf12be202ab12409ead469d6d5aba6b8aab837db614d057b6"]
            
            card.walletPublicKey = "55C57F7F73B884B1B1A36FC6E3E4106AB158236411D3CADAF55CCD2AD83FA9F2"
            card.walletPublicKeyBytesArray = Array(card.walletPublicKey.hexData()!)
            let signFromCard: [UInt8] = Array(repeating: 0, count: 64)
            
            let walletAddress = "Ae2tdPwUPEZDGJzac6kD61C5YtMdvCgf4iV6C1Hxsqa952wndVQwyP2HYKZ"
            let unspentOutputs = ["6f5d271bb154628cf12be202ab12409ead469d6d5aba6b8aab837db614d057b6"]
            let targetAddress = "Ae2tdPwUPEYykj3kHNLjrHd6jisMhAdDDRbobq7zhL7koTipv1DfPHn7rN1"
            
            let dummyFee = NSDecimalNumber(0.0).multiplying(byPowerOf10: Int16(6), withBehavior: nil).stringValue
            let transaction = CardanoTransaction(unspentOutputs: unspentOutputs, 
                                                 cardWalletAddress: walletAddress, 
                                                 targetAddress: targetAddress, 
                                                 amount: "600000",
                                                 walletBalance: "800000",
                                                 feeValue: dummyFee,
                                                 isIncludeFee: true)
            
            cardanoEngine.transaction = transaction

            cardanoEngine.sendToBlockchain(signFromCard: signFromCard, completion: { (success) in
                expectation.fulfill()
            })
            
        }
        
        wait(for: [expectation], timeout: 5)
    }
    
    func testPendingTransactionsStorage() {
        let expectation = XCTestExpectation(description: "Card values parsing check")
        
        var firstCard: CardViewModel!
        var secondCard: CardViewModel!
        
        let storage = CardanoPendingTransactionsStorage.shared
        let expirationTimeoutSeconds: Int = 60
        
        DispatchQueue.global().async {
            self.validateCardWith(payload: Data(TestData.cardano.rawValue.asciiHexToData()!)) { (card) in
                firstCard = card
                
                self.validateCardWith(payload: Data(TestData.rsk.rawValue.asciiHexToData()!)) { (card) in
                    secondCard = card
                }
            }
        }
        
        DispatchQueue.global().async {
            while firstCard == nil || secondCard == nil {
                // Wait
            }
            
            // MARK: Single card
            
            storage.purge()
            XCTAssert(!storage.hasPendingTransactions(firstCard))
            
            let transactionId = "a6ecdbca5eefc0e6c1f09f9c75f05b754f97acc2981a2989f30f006a293a4c5b"
            storage.append(transactionId: transactionId, card: firstCard, expirationTimeoutSeconds: expirationTimeoutSeconds)
            XCTAssert(storage.hasPendingTransactions(firstCard))
            
            storage.cleanup(existingTransactionsIds: [transactionId], card: firstCard)
            XCTAssert(!storage.hasPendingTransactions(firstCard))
            
            // MARK: Multiple cards
            
            let anotherTransactionId = "8c647bd8ea740d2d2d9c3273649b52206e69af72f8cb149973d15e8dd960a4c6"
            let yetOneMoreTransactionId = "7ef1269543e7db8ab336f8adb2ab4da1718c1263a0fd1ddf54d59e697def558c"
            
            storage.append(transactionId: anotherTransactionId, card: firstCard, expirationTimeoutSeconds: expirationTimeoutSeconds)
            XCTAssert(!storage.hasPendingTransactions(secondCard))
            
            storage.append(transactionId: transactionId, card: secondCard, expirationTimeoutSeconds: expirationTimeoutSeconds)
            storage.append(transactionId: yetOneMoreTransactionId, card: secondCard, expirationTimeoutSeconds: expirationTimeoutSeconds)
            
            XCTAssert(storage.hasPendingTransactions(firstCard))
            XCTAssert(storage.hasPendingTransactions(secondCard))
            
            storage.cleanup(existingTransactionsIds: [anotherTransactionId, yetOneMoreTransactionId], card: secondCard)
            XCTAssert(storage.hasPendingTransactions(secondCard))
            
            storage.cleanup(existingTransactionsIds: [transactionId], card: secondCard)
            XCTAssert(!storage.hasPendingTransactions(secondCard))
            
            storage.cleanup(existingTransactionsIds: [transactionId], card: firstCard)
            XCTAssert(storage.hasPendingTransactions(firstCard))
            
            storage.cleanup(existingTransactionsIds: [anotherTransactionId], card: firstCard)
            XCTAssert(!storage.hasPendingTransactions(firstCard))
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2)
    }
    
    func testPendingTransactionsExpiration() {
        let expectation = XCTestExpectation(description: "Card values parsing check")
        
        let storage = CardanoPendingTransactionsStorage.shared
        
        validateCardWith(payload: Data(TestData.cardano.rawValue.asciiHexToData()!)) { (card) in
            storage.purge()
            XCTAssert(!storage.hasPendingTransactions(card))
            
            let transactionId = "a6ecdbca5eefc0e6c1f09f9c75f05b754f97acc2981a2989f30f006a293a4c5b"
            storage.append(transactionId: transactionId, card: card, expirationTimeoutSeconds: 2)
            
            DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + 1, execute: { 
                storage.cleanup(existingTransactionsIds: [], card: card)
                XCTAssert(storage.hasPendingTransactions(card))
                
                DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + 2, execute: {
                    storage.cleanup(existingTransactionsIds: [], card: card)
                    XCTAssert(!storage.hasPendingTransactions(card))
                    
                    expectation.fulfill()
                })

            })
            
        }
        
        wait(for: [expectation], timeout: 5)
    }

}

extension CardanoTests {
    
    func validateCardWith(payload: Data, validationBlock: @escaping (CardViewModel) -> Void) {
        currentValidationBlock = validationBlock
        
        session = TangemSession(payload: payload, delegate: self)
        session?.start()
    }
    
}

extension CardanoTests: TangemSessionDelegate {
    
    func tangemSessionDidRead(card: CardViewModel) {
        currentValidationBlock?(card)
    }
    
    func tangemSessionDidFailWith(error: TangemSessionError) {
        
    }
    
}
