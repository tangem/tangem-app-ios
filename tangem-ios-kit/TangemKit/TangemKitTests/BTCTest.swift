//
//  BTCTest.swift
//  TangemKitTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Smart Cash AG. All rights reserved.
//

import Foundation
import XCTest

@testable import TangemKit

class BTCTest: XCTestCase {
    func testHashForSignBTC() {
        let expectation = XCTestExpectation(description: "Done")
        
        let ethalonHashToSign: [UInt8] = [-71, -98, -80, -47, -88, 7, 76, 102, 38, 85, -97, 48, -8, -84, 69, 90, 66, -79, 66, -118, 4, -106, -10, -11, -8, 50, -90, 89, 77, -63, 74, 35, 81, 26, 3, 110, 121, 125, -120, 105, -107, 8, -2, 87, 45, 52, 22, 48, 69, -76, -105, -121, 94, 123, -77, 44, -43, 27, -31, -90, -115, 13, -77, -27, -52, 54, 27, 87, -64, 34, 19, 55, 7, -81, -53, 32, 34, 55, -44, 107, -21, 98, 95, 27, 66, 119, 126, -17, 37, -47, -122, 29, -46, -65, -39, 90, 127, -122, -40, 113, -13, -96, -81, 104, -44, -9, -12, 96, -31, -27, 94, 104, -50, 61, 14, 121, 44, 30, -119, 53, 64, 8, 66, 47, -66, 78, 118, 17, 22, -17, -58, -95, -23, -94, 42, 48, -44, -11, -114, -83, -83, 80, -72, -40, -103, 104, 30, 94, 55, 98, -11, 42, 21, -18, -25, 5, 112, -71, 43, 95].bytes
        
        let card = CardViewModel()
        card.walletPublicKey = "181xx3H13FPXfXmLH1L5wx8EytnFUDicx7" //dummy
        card.blockchainName  = "bitcoin"
        let engine = BTCEngine(card: card)
        engine.walletAddress = "181xx3H13FPXfXmLH1L5wx8EytnFUDicx7"
        card.cardEngine = engine

        
        let operationQueue = OperationQueue()
        let op = card.balanceRequestOperation(onSuccess: { card in
            
            let hashToSign = engine.getHashForSignature(amount: "0.0005",
                                                        fee: "0.00000001", includeFee: true,
                                                        targetAddress: "14w5usEvtU54feaMc1ptqjYTLRbs8u2js6")?.bytes
            
            XCTAssertEqual(hashToSign, ethalonHashToSign)
            expectation.fulfill()
        }) { err in
            XCTAssert(false)
        }
        
        operationQueue.addOperation(op!)
        
        wait(for: [expectation], timeout: 30.0)
    }
    
    func testConversion() {
        XCTAssertEqual(254.byte, UInt8(254))
        XCTAssertEqual(255.bytes2.count, 2)
        XCTAssertEqual(65534.bytes2.count, 2)
        XCTAssertEqual(65535.bytes4.count, 4)
    }
    
    func testTransactionPostProcessing() {
        let expectation = XCTestExpectation(description: "Done")
        
        let ethalonTxToSend = [1, 0, 0, 0, 5, 19, -34, -46, 104, 117, 48, -73, 81, 89, 110, -120, 34, 97, 92, 62, 125, -1, 26, 122, -87, -82, 92, -99, 121, 72, -127, 115, 83, -47, -123, -107, -117, 0, 0, 0, 0, -118, 71, 48, 68, 2, 32, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 32, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 65, 4, -83, -66, 118, -99, 20, 111, -75, -86, 113, 50, 105, -8, 81, 44, -126, 116, -2, -27, 104, 64, -9, -116, -50, 33, -98, 62, 70, -7, -61, -36, 40, 65, 102, -20, -121, -27, 94, 25, -28, 36, 123, -61, 13, -30, -56, -16, -45, 6, 6, -17, 117, -64, -51, -84, 40, 126, 14, 76, 32, 44, -95, -92, 37, 59, -1, -1, -1, -1, 83, -88, -44, -14, -95, -43, 123, 82, 12, 92, 82, 66, -95, -7, -38, -2, 65, -111, 103, 70, 126, -85, 8, 48, 7, 39, 111, 114, -42, -12, 66, -17, 0, 0, 0, 0, -118, 71, 48, 68, 2, 32, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 32, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 65, 4, -83, -66, 118, -99, 20, 111, -75, -86, 113, 50, 105, -8, 81, 44, -126, 116, -2, -27, 104, 64, -9, -116, -50, 33, -98, 62, 70, -7, -61, -36, 40, 65, 102, -20, -121, -27, 94, 25, -28, 36, 123, -61, 13, -30, -56, -16, -45, 6, 6, -17, 117, -64, -51, -84, 40, 126, 14, 76, 32, 44, -95, -92, 37, 59, -1, -1, -1, -1, -95, -65, 58, -93, 118, 64, -76, 20, -37, -82, 25, 107, -70, -68, 12, -121, 87, 53, 127, 126, -37, 24, -23, -14, 125, -84, -49, -85, -83, 54, 15, -99, 1, 0, 0, 0, -118, 71, 48, 68, 2, 32, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 32, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 65, 4, -83, -66, 118, -99, 20, 111, -75, -86, 113, 50, 105, -8, 81, 44, -126, 116, -2, -27, 104, 64, -9, -116, -50, 33, -98, 62, 70, -7, -61, -36, 40, 65, 102, -20, -121, -27, 94, 25, -28, 36, 123, -61, 13, -30, -56, -16, -45, 6, 6, -17, 117, -64, -51, -84, 40, 126, 14, 76, 32, 44, -95, -92, 37, 59, -1, -1, -1, -1, 48, -121, 61, 53, -79, -52, 62, -70, -101, -116, 105, -87, -32, 93, 2, 50, 53, 74, 30, -63, 93, -117, -3, 84, -119, -70, -55, -12, -35, 58, 120, 10, 0, 0, 0, 0, -118, 71, 48, 68, 2, 32, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 32, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 65, 4, -83, -66, 118, -99, 20, 111, -75, -86, 113, 50, 105, -8, 81, 44, -126, 116, -2, -27, 104, 64, -9, -116, -50, 33, -98, 62, 70, -7, -61, -36, 40, 65, 102, -20, -121, -27, 94, 25, -28, 36, 123, -61, 13, -30, -56, -16, -45, 6, 6, -17, 117, -64, -51, -84, 40, 126, 14, 76, 32, 44, -95, -92, 37, 59, -1, -1, -1, -1, 83, 100, -22, 53, -108, -110, -13, 54, 39, -91, 37, 72, 36, 83, 101, 3, -79, 38, -43, 47, 115, -72, -16, -30, -18, 75, 123, 13, -113, 82, -84, -101, 0, 0, 0, 0, -118, 71, 48, 68, 2, 32, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 32, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 65, 4, -83, -66, 118, -99, 20, 111, -75, -86, 113, 50, 105, -8, 81, 44, -126, 116, -2, -27, 104, 64, -9, -116, -50, 33, -98, 62, 70, -7, -61, -36, 40, 65, 102, -20, -121, -27, 94, 25, -28, 36, 123, -61, 13, -30, -56, -16, -45, 6, 6, -17, 117, -64, -51, -84, 40, 126, 14, 76, 32, 44, -95, -92, 37, 59, -1, -1, -1, -1, 2, 79, -61, 0, 0, 0, 0, 0, 0, 25, 118, -87, 20, 43, 34, -16, 110, -58, -89, 52, 80, -30, -65, 63, 92, -23, 33, -91, -90, -50, 39, -107, 8, -120, -84, -13, 83, 2, 0, 0, 0, 0, 0, 25, 118, -87, 20, 76, -9, -107, -107, -3, 123, 124, 70, -84, -50, -92, -123, -117, 32, -11, -78, -75, 19, -32, 39, -120, -84, 0, 0, 0, 0].bytes
        
    
        let card = CardViewModel()
        card.walletPublicKey = "181xx3H13FPXfXmLH1L5wx8EytnFUDicx7" //dummy
        card.blockchainName  = "bitcoin"
        let engine = BTCEngine(card: card)
        engine.walletAddress = "181xx3H13FPXfXmLH1L5wx8EytnFUDicx7"
        card.cardEngine = engine
        
        
        let operationQueue = OperationQueue()
        let op = card.balanceRequestOperation(onSuccess: { card in
            
            let hashToSign = engine.getHashForSignature(amount: "0.0005",
                                                        fee: "0.00000001", includeFee: true,
                                                        targetAddress: "14w5usEvtU54feaMc1ptqjYTLRbs8u2js6")!.bytes
            
            let dummySignFromCard = [UInt8](repeating: UInt8(0x01), count: 64 * hashToSign.count)
            let pkey = [4, -83, -66, 118, -99, 20, 111, -75, -86, 113, 50, 105, -8, 81, 44, -126, 116, -2, -27, 104, 64, -9, -116, -50, 33, -98, 62, 70, -7, -61, -36, 40, 65, 102, -20, -121, -27, 94, 25, -28, 36, 123, -61, 13, -30, -56, -16, -45, 6, 6, -17, 117, -64, -51, -84, 40, 126, 14, 76, 32, 44, -95, -92, 37, 59].bytes
            
            
            let txToSend = engine.buildTxForSend(signFromCard: dummySignFromCard, txRefs: engine.blockcypherResponse!.txrefs!, publicKey: pkey)!
            XCTAssertEqual(txToSend, ethalonTxToSend)
            expectation.fulfill()
        }) { err in
            XCTAssert(false)
        }
        
        operationQueue.addOperation(op!)
        
        wait(for: [expectation], timeout: 30.0)
    }
    
    func testFee() {
        let expectation = XCTestExpectation(description: "Done")
        
        let card = CardViewModel()
        card.walletPublicKey = "181xx3H13FPXfXmLH1L5wx8EytnFUDicx7" //dummy
        card.blockchainName  = "bitcoin"
        let engine = BTCEngine(card: card)
        engine.walletAddress = "181xx3H13FPXfXmLH1L5wx8EytnFUDicx7"
        card.cardEngine = engine
        card.walletPublicKeyBytesArray = [4, -83, -66, 118, -99, 20, 111, -75, -86, 113, 50, 105, -8, 81, 44, -126, 116, -2, -27, 104, 64, -9, -116, -50, 33, -98, 62, 70, -7, -61, -36, 40, 65, 102, -20, -121, -27, 94, 25, -28, 36, 123, -61, 13, -30, -56, -16, -45, 6, 6, -17, 117, -64, -51, -84, 40, 126, 14, 76, 32, 44, -95, -92, 37, 59].bytes
        
        let operationQueue = OperationQueue()
        let op = card.balanceRequestOperation(onSuccess: { _ in
           
            engine.getFee(targetAddress: "14w5usEvtU54feaMc1ptqjYTLRbs8u2js6", amount: "0.0005") { fee in
                guard let fee = fee else {
                    XCTAssertNotNil(nil, "not loaded")
                    return
                }
                print("min fee: \(fee.min) normal fee: \(fee.normal) max fee \(fee.max)")
                expectation.fulfill()
            }

        }) { err in
            XCTAssert(false)
        }
        
        operationQueue.addOperation(op!)
        
        wait(for: [expectation], timeout: 30.0)
    }
}
