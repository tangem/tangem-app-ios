//
//  TangemKitTests.swift
//  TangemKitTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Smart Cash AG. All rights reserved.
//

import XCTest
import CommonCrypto
import SwiftCBOR
import Sodium
@testable import TangemKit

class TangemKitTests: XCTestCase {

    var currentValidationBlock: ((CardViewModel) -> Void)?
    var currentExpectation: XCTestExpectation?
    
    func testSEEDTokenCard() {
        validateCardWith(payload: Data(TestData.seed.rawValue.asciiHexToData()!)) { (card) in
            self.validateSEEDCard(card)
        }
    }
    
    func testBTCCard() {
        validateCardWith(payload: Data(TestData.btcWallet.rawValue.asciiHexToData()!)) { (card) in
            self.validateBTCCard(card)
        }
    }
    
    func testFailingCard() {
        validateCardWith(payload: Data(TestData.failing.rawValue.asciiHexToData()!)) { (card) in
            
        }
    }
    
    func testTokenContractAddress() {
        validateCardWith(payload: Data(TestData.seed.rawValue.asciiHexToData()!)) { (card) in
            card.tokenContractAddress = "0x4E7Bd88E3996f48E2a24D15E37cA4C02B4D134d2"
            
            card.batchId = 0x0019
            XCTAssertEqual(card.tokenContractAddress, "0x0c056b0cda0763cc14b8b2d6c02465c91e33ec72")
            
            card.batchId = 0x0017
            XCTAssertEqual(card.tokenContractAddress, "0x9Eef75bA8e81340da9D8d1fd06B2f313DB88839c")
            
            card.batchId = 0x0012
            XCTAssertEqual(card.tokenContractAddress, "0x4E7Bd88E3996f48E2a24D15E37cA4C02B4D134d2")
        }
    }
    
    func testCardImageNames() {
        
        validateCardWith(payload: Data(TestData.btcWallet.rawValue.asciiHexToData()!)) { (card) in
            
            guard let bundle = Bundle(identifier: "com.tangem.TangemKit") else {
                XCTFail()
                return
            }
            
            let btc001ImageName = UIImage(named: "card-btc001", in: bundle, compatibleWith: nil)
            let btc005ImageName = UIImage(named: "card-btc005", in: bundle, compatibleWith: nil)
            
            card.batchId = 0x0010
            card.cardID = "CB02 0000 0000 0000"
            XCTAssertEqual(card.image, btc001ImageName)
            card.cardID = "CB02 0000 0002 4990"
            XCTAssertEqual(card.image, btc001ImageName)
            
            card.cardID = "CB02 0000 0002 5000"
            XCTAssertEqual(card.image, btc005ImageName)
            card.cardID = "CB02 0000 0004 9990"
            XCTAssertEqual(card.image, btc005ImageName)
            
            card.cardID = "CB05 0000 1000 0000"
            XCTAssertEqual(card.image, btc001ImageName)
            
            card.batchId = 0x0008
            card.cardID = "AE01 0000 0000 0000"
            XCTAssertEqual(card.image, btc001ImageName)
            
            card.cardID = "AE01 0000 0000 4990"
            XCTAssertEqual(card.image, btc001ImageName)
            
            card.cardID = "AE01 0000 0000 5000"
            XCTAssertEqual(card.image, btc005ImageName)
            
            card.cardID = "AA01 0000 0000 0000"
            XCTAssertEqual(card.image, btc001ImageName)
            
            card.cardID = "AA01 0000 0000 4990"
            XCTAssertEqual(card.image, btc001ImageName)
            
            card.cardID = "AA01 0000 0000 5000"
            XCTAssertEqual(card.image, btc005ImageName)
        }
        
    }
    
    func testRSK() {
        validateCardWith(payload: Data(TestData.rsk.rawValue.asciiHexToData()!)) { (card) in
            XCTAssertEqual(card.blockchainName, "RSK")
            XCTAssertEqual(card.cardEngine.blockchainDisplayName, "Rootstock")
            XCTAssertEqual(card.node, "public-node.rsk.co")
        }
    }
    
    func testCardano() {
        validateCardWith(payload: Data(TestData.cardano.rawValue.asciiHexToData()!)) { (card) in
            XCTAssertEqual(card.blockchainName, "CARDANO")
            XCTAssertEqual(card.cardEngine.blockchainDisplayName, "Cardano")
            XCTAssertEqual(card.node, "explorer2.adalite.io")
        }
    }
    
    func testRipple() {
        validateCardWith(payload: Data(TestData.xrp.rawValue.asciiHexToData()!)) { (card) in
            XCTAssertEqual(card.address, "rNzaANSNTjMXJsFn2JrXPJhsULWqJLpfAq")
            XCTAssertEqual(card.blockchainName, "XRP")
            XCTAssertEqual(card.cardEngine.blockchainDisplayName, "Ripple")
            XCTAssertEqual(card.node, "explorer2.adalite.io")
        }
    }
    
    func testRippleEdDSA() {
        validateCardWith(payload: Data(TestData.xrpEdDSA.rawValue.asciiHexToData()!)) { (card) in
            
            self.verifyECDSASignatureVerification(card: card)
            
            XCTAssertEqual(card.address, "rwWMNBs2GtJwfX7YNVV1sUYaPy6DRmDHB4")
            XCTAssertEqual(card.blockchainName, "XRP")
            XCTAssertEqual(card.cardEngine.blockchainDisplayName, "Ripple")
            XCTAssertEqual(card.node, "explorer2.adalite.io")
        } 
    }
    
    func verifyECDSASignatureVerification(card: CardViewModel) {

        let inputBinary = dataWithHexString(hex: card.challenge! + card.salt!)
        
        guard let shaBinary = sha256(inputBinary), let messageData = shaBinary.hexEncodedString().asciiHexToData() else {
            XCTFail()
            return
        }
        
        let result = Ed25519.verify(card.signArr, messageData, card.walletPublicKeyBytesArray)
        XCTAssert(result)
    }

}

extension TangemKitTests {
    
    func validateCardWith(payload: Data, validationBlock: @escaping (CardViewModel) -> Void) {
        let expectation = XCTestExpectation(description: "Card values parsing check")
        currentExpectation = expectation
        currentValidationBlock = validationBlock
        
        let session = TangemSession(payload: payload, delegate: self)
        session.start()
        
        self.wait(for: [expectation], timeout: 5)
    }
    
    func validateSEEDCard(_ card: CardViewModel) {
        XCTAssertEqual(card.cardID, "CB03 0000 0000 0002")
        XCTAssertEqual(card.address, "0x67a9cc24956648d3afe6099f89c25cbb6b49b42d")
        XCTAssertEqual(card.address, "0x67a9cc24956648d3afe6099f89c25cbb6b49b42d")
        XCTAssertEqual(card.walletPublicKey, "040690E1BEB95361BE2D4F2BB05CF48E7EAC57FD82005EC39D703925E7A2BD60509BB194716969A44EFAD3BF2375541FA42D930CC5B94464B972441527B5229D3D")
        XCTAssertEqual(card.cardEngine.blockchainDisplayName, "Ethereum")
        XCTAssertEqual(card.blockchainName, "ETH")
        XCTAssertEqual(card.issuer, "SUPERBLOOM\0")
        XCTAssertEqual(card.manufactureDateTime, "Jun 22, 2018")
        XCTAssertEqual(card.manufactureSignature, "A8A2C072306C3C3302B4DEBDBAEF9FCC0483B6BB588AB6284FD7A2CC9B144798B510404B96D5F485238758D4CAB81ABACAC1AAAD8B40865FF09E80AB648801DE")
        XCTAssertEqual(card.batchId, 0x0012)
        XCTAssertEqual(card.tokenSymbol, "SEED")
        XCTAssertEqual(card.walletUnits, "ETH")
        XCTAssertEqual(card.tokenDecimal, 18)
        XCTAssertEqual(card.cardEngine.exploreLink, "https://etherscan.io/token/0x4E7Bd88E3996f48E2a24D15E37cA4C02B4D134d2?a=0x67a9cc24956648d3afe6099f89c25cbb6b49b42d")
        XCTAssertEqual(card.node, "mainnet.infura.io")
        XCTAssertEqual(card.salt, "c7f69ad955dfe750d1c634769545bbc3")
        XCTAssertEqual(card.challenge, "88fdd29ed228c5f5d0a93fad269d679c")
        XCTAssertEqual(card.signedHashes, "00000000")
        XCTAssertEqual(card.tokenContractAddress, "0x4E7Bd88E3996f48E2a24D15E37cA4C02B4D134d2")
    }
    
    func validateBTCCard(_ card: CardViewModel) {
        XCTAssertEqual(card.cardID, "CB02 0000 0001 3907")
        XCTAssertTrue(card.isWallet)
        XCTAssertEqual(card.address, "1Hi8aU71rsAGdEeMRm7sVKFZqHwwVdacSd")
        XCTAssertEqual(card.address, "1Hi8aU71rsAGdEeMRm7sVKFZqHwwVdacSd")
        XCTAssertEqual(card.walletPublicKey, "04F71C39C9ECD664F56CFFB1F3045765A5EF81B08855C9AEA37B5D64A601E715E9BF26A4CD002CC94CD5246FCCC3F2F335AD63B7F834E969D9EA6A6B40070BB561")
        XCTAssertEqual(card.cardEngine.blockchainDisplayName, "Bitcoin")
        XCTAssertEqual(card.blockchainName, "BTC")
        XCTAssertEqual(card.issuer, "TANGEM\0")
        XCTAssertEqual(card.manufactureDateTime, "May 7, 2018")
        XCTAssertEqual(card.manufactureSignature, "EB32AE43D9C0D5DFB0268742C4C627C67022EBB8EE6A1E079198903B42ADDE9EF3041CD71D0DC067B2545D61B3168CBAB141F3F743461CD79C3087D3D9DBFB20")
        XCTAssertEqual(card.batchId, 0x0010)
        XCTAssertEqual(card.walletUnits, "BTC")
        XCTAssertEqual(card.cardEngine.exploreLink, "https://blockchain.info/address/1Hi8aU71rsAGdEeMRm7sVKFZqHwwVdacSd")
        XCTAssertEqual(card.salt, "2165ceeb05566fbbaecf894b304aa5d9")
        XCTAssertEqual(card.challenge, "d08d22da56475300d986434b675c5715")
        XCTAssertEqual(card.signedHashes, "00000000")
    }
    
}

extension TangemKitTests: TangemSessionDelegate {
    
    func tangemSessionDidRead(card: CardViewModel) {
        currentValidationBlock?(card)
        currentExpectation?.fulfill()
    }
    
    func tangemSessionDidFailWith(error: TangemSessionError) {
        
    }
    
}
