//
//  TangemTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Smart Cash AG. All rights reserved.
//

import XCTest
import CommonCrypto

class TangemTests: XCTestCase {
    
    func testSEEDTokenCard() {
        let payload = TestData.seed.rawValue.asciiHexToData()!
        
        let expectation = XCTestExpectation(description: "Card values parsing check")
        
        let operation = CardParsingOperation(payload: Data(payload)) { (result) in
            guard case .success(let card) = result else {
                XCTFail()
                return
            }
            
            self.validateSEEDCard(card)
            expectation.fulfill()
        }
        operation.start()
        
        self.wait(for: [expectation], timeout: 5)
        
    }
    
    func testBTCCard() {
        let payload = TestData.btcWallet.rawValue.asciiHexToData()!
        
        let expectation = XCTestExpectation(description: "Card values parsing check")
        
        let operation = CardParsingOperation(payload: Data(payload)) { (result) in
            guard case .success(let card) = result else {
                XCTFail()
                return
            }
            
            self.validateBTCCard(card)
            expectation.fulfill()
        }
        operation.start()
        
        self.wait(for: [expectation], timeout: 5)
        
    }
    
    func testTokenContractAddress() {
        var card = Card()
        card.tokenContractAddress = "0x4E7Bd88E3996f48E2a24D15E37cA4C02B4D134d2"
        
        card.batchId = 0x0019
        XCTAssertEqual(card.tokenContractAddress, "0x0c056b0cda0763cc14b8b2d6c02465c91e33ec72")
        
        card.batchId = 0x0017
        XCTAssertEqual(card.tokenContractAddress, "0x9Eef75bA8e81340da9D8d1fd06B2f313DB88839c")
        
        card.batchId = 0x0012
        XCTAssertEqual(card.tokenContractAddress, "0x4E7Bd88E3996f48E2a24D15E37cA4C02B4D134d2")
    }
    
    func testCardImageNames() {
        
        let btc001ImageName = "card-btc001"
        let btc005ImageName = "card-btc005"
        
        var card = Card()
        
        card.batchId = 0x0010
        card.cardID = "CB02 0000 0000 0000"
        XCTAssertEqual(card.imageName, btc001ImageName)
        card.cardID = "CB02 0000 0002 4990"
        XCTAssertEqual(card.imageName, btc001ImageName)
        
        card.cardID = "CB02 0000 0002 5000"
        XCTAssertEqual(card.imageName, btc005ImageName)
        card.cardID = "CB02 0000 0004 9990"
        XCTAssertEqual(card.imageName, btc005ImageName)
        
        card.cardID = "CB05 0000 1000 0000"
        XCTAssertEqual(card.imageName, btc001ImageName)
        
        card.batchId = 0x0008
        card.cardID = "AE01 0000 0000 0000"
        XCTAssertEqual(card.imageName, btc001ImageName)
        
        card.cardID = "AE01 0000 0000 4990"
        XCTAssertEqual(card.imageName, btc001ImageName)
        
        card.cardID = "AE01 0000 0000 5000"
        XCTAssertEqual(card.imageName, btc005ImageName)
        
        card.cardID = "AA01 0000 0000 0000"
        XCTAssertEqual(card.imageName, btc001ImageName)
        
        card.cardID = "AA01 0000 0000 4990"
        XCTAssertEqual(card.imageName, btc001ImageName)
        
        card.cardID = "AA01 0000 0000 5000"
        XCTAssertEqual(card.imageName, btc005ImageName)
    }

}

extension TangemTests {
    
    func validateSEEDCard(_ card: Card) {
        XCTAssertEqual(card.cardID, "CB03 0000 0000 0002")
        XCTAssertEqual(card.address, "0x67a9cc24956648d3afe6099f89c25cbb6b49b42d")
        XCTAssertEqual(card.ethAddress, "0x67a9cc24956648d3afe6099f89c25cbb6b49b42d")
        XCTAssertEqual(card.hexPublicKey, "040690E1BEB95361BE2D4F2BB05CF48E7EAC57FD82005EC39D703925E7A2BD60509BB194716969A44EFAD3BF2375541FA42D930CC5B94464B972441527B5229D3D")
        XCTAssertEqual(card.blockchain, "Ethereum")
        XCTAssertEqual(card.blockchainName, "ETH")
        XCTAssertEqual(card.issuer, "SUPERBLOOM\0")
        XCTAssertEqual(card.manufactureDateTime, "Jun 22, 2018")
        XCTAssertEqual(card.manufactureSignature, "A8A2C072306C3C3302B4DEBDBAEF9FCC0483B6BB588AB6284FD7A2CC9B144798B510404B96D5F485238758D4CAB81ABACAC1AAAD8B40865FF09E80AB648801DE")
        XCTAssertEqual(card.batchId, 0x0012)
        XCTAssertFalse(card.isTestNet)
        XCTAssertEqual(card.tokenSymbol, "SEED")
        XCTAssertEqual(card.walletUnits, "SEED")
        XCTAssertEqual(card.tokenDecimal, 18)
        XCTAssertEqual(card.link, "https://etherscan.io/address/0x67a9cc24956648d3afe6099f89c25cbb6b49b42d")
        XCTAssertEqual(card.node, "mainnet.infura.io")
        XCTAssertEqual(card.salt, "c7f69ad955dfe750d1c634769545bbc3")
        XCTAssertEqual(card.challenge, "88fdd29ed228c5f5d0a93fad269d679c")
        XCTAssertEqual(card.signedHashes, "00000000")
        XCTAssertEqual(card.tokenContractAddress, "0x4E7Bd88E3996f48E2a24D15E37cA4C02B4D134d2")
    }
    
    func validateBTCCard(_ card: Card) {
        XCTAssertEqual(card.cardID, "CB02 0000 0001 3907")
        XCTAssertTrue(card.isWallet)
        XCTAssertEqual(card.address, "1Hi8aU71rsAGdEeMRm7sVKFZqHwwVdacSd")
        XCTAssertEqual(card.btcAddressTest, "mxE5sXBzftbXQM7y9L6FKETthHYeUduTsT")
        XCTAssertEqual(card.btcAddressMain, "1Hi8aU71rsAGdEeMRm7sVKFZqHwwVdacSd")
        XCTAssertEqual(card.hexPublicKey, "04F71C39C9ECD664F56CFFB1F3045765A5EF81B08855C9AEA37B5D64A601E715E9BF26A4CD002CC94CD5246FCCC3F2F335AD63B7F834E969D9EA6A6B40070BB561")
        XCTAssertEqual(card.blockchain, "Bitcoin")
        XCTAssertEqual(card.blockchainName, "BTC")
        XCTAssertEqual(card.issuer, "TANGEM\0")
        XCTAssertEqual(card.manufactureDateTime, "May 7, 2018")
        XCTAssertEqual(card.manufactureSignature, "EB32AE43D9C0D5DFB0268742C4C627C67022EBB8EE6A1E079198903B42ADDE9EF3041CD71D0DC067B2545D61B3168CBAB141F3F743461CD79C3087D3D9DBFB20")
        XCTAssertEqual(card.batchId, 0x0010)
        XCTAssertFalse(card.isTestNet)
        XCTAssertEqual(card.walletUnits, "BTC")
        XCTAssertEqual(card.link, "https://blockchain.info/address/1Hi8aU71rsAGdEeMRm7sVKFZqHwwVdacSd")
        XCTAssertEqual(card.salt, "2165ceeb05566fbbaecf894b304aa5d9")
        XCTAssertEqual(card.challenge, "d08d22da56475300d986434b675c5715")
        XCTAssertEqual(card.signedHashes, "00000000")
    }
    
}
