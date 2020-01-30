//
//  ETHTest.swift
//  TangemKitTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Smart Cash AG. All rights reserved.
//
import Foundation
import XCTest
import BigInt
import web3swift

@testable import TangemKit

class ETHTest: XCTestCase {
    func testHashForSignEth() {
        let ethalonHashToSign: [UInt8] = "25012a63fafb71ab861e3169db1916d4ee3549b98e6e3d2ef883a5af166dfecc".asciiHexToData()!
        
        let card = CardViewModel()
        card.walletPublicKey = "0x4dcc15cc2756d2b3b39c66c0a54d9265d8c386e0"
        
        let ethEngine = ETHEngine(card: card)
        ethEngine.txCount = 18
        let hashToSign = ethEngine.getHashForSignature(amount: "0.000001", fee: "0.00042", includeFee: false, targetAddress: "0x4dcc15cc2756d2b3b39c66c0a54d9265d8c386e0")?.bytes
        XCTAssertEqual(hashToSign, ethalonHashToSign)
    }
    
    func testPostSignEth() {
        
        let ethalonBytesToSend = [-8, 105, 1, -124, 59, -102, -54, 0, -126, 82, 8, -108, -51, 6, -127, 39, 39, 10, 125, -39, 122, 90, 90, 80, 84, 116, 63, 46, 105, -79, -6, -63, -122, 90, -13, 16, 122, 64, 0, -128, 37, -96, -34, 83, 109, -56, -120, -100, 6, -22, 75, -98, 53, 32, -90, 59, 42, 15, -53, 110, -25, -34, -5, -56, 0, 80, -9, -29, -31, 10, -3, -26, 114, -99, -96, 54, -42, 124, -35, 30, 64, 21, -40, -93, 46, 54, -23, 24, 58, 13, 126, -121, 46, 18, 2, -122, 14, 91, -103, 117, -70, 34, -75, 60, -53, -59, 107].bytes
        
        let ethalonStringToSend = "0xf86901843b9aca0082520894cd068127270a7dd97a5a5a5054743f2e69b1fac1865af3107a40008025a0de536dc8889c06ea4b9e3520a63b2a0fcb6ee7defbc80050f7e3e10afde6729da036d67cdd1e4015d8a32e36e9183a0d7e872e1202860e5b9975ba22b53ccbc56b"
        
        let ethalonPbKey = [4, 74, 107, 83, -17, -111, -114, 101, 38, -21, -37, 117, -47, 62, -103, -69, 36, -10, 119, 118, 57, 48, -22, -68, 125, 44, 90, -107, 124, 4, 102, 59, -113, -116, 14, -38, -40, 126, -24, 9, -37, 38, 38, 62, -33, -76, -4, -51, 112, 9, -44, 61, 34, 55, 31, 92, 71, -15, -7, 21, -58, -85, -24, -22, -64].bytes
        
        let pkey="044A6B53EF918E6526EBDB75D13E99BB24F677763930EABC7D2C5A957C04663B8F8C0EDAD87EE809DB26263EDFB4FCCD7009D43D22371F5C47F1F915C6ABE8EAC0".asciiHexToData()!
        
        XCTAssertEqual(ethalonPbKey, pkey)
        
        let signBytesFromCard = [-34, 83, 109, -56, -120, -100, 6, -22, 75, -98, 53, 32, -90, 59, 42, 15, -53, 110, -25, -34, -5, -56, 0, 80, -9, -29, -31, 10, -3, -26, 114, -99, 54, -42, 124, -35, 30, 64, 21, -40, -93, 46, 54, -23, 24, 58, 13, 126, -121, 46, 18, 2, -122, 14, 91, -103, 117, -70, 34, -75, 60, -53, -59, 107].bytes
        
        
        let iosSignBytes = "de536dc8889c06ea4b9e3520a63b2a0fcb6ee7defbc80050f7e3e10afde6729d36d67cdd1e4015d8a32e36e9183a0d7e872e1202860e5b9975ba22b53ccbc56b".asciiHexToData()!
        XCTAssertEqual(signBytesFromCard, iosSignBytes)
        
        
        let card = CardViewModel()
        
        card.walletPublicKey = "0xcd068127270a7dd97a5a5a5054743f2e69b1fac1" //just dummy to avoid crash
        card.walletPublicKeyBytesArray = pkey
        
        
        let ethEngine = ETHEngine(card: card)
        ethEngine.txCount = 1
        _ = ethEngine.getHashForSignature(amount: "0.0001", fee: "0.000021", includeFee: false, targetAddress: "0xcd068127270a7dd97a5a5a5054743f2e69b1fac1")?.bytes
        
        let toSendBytes = ethEngine.getHashForSend(signFromCard: signBytesFromCard)!.bytes
        let toSendString = "0xf86901843b9aca0082520894cd068127270a7dd97a5a5a5054743f2e69b1fac1865af3107a40008025a0de536dc8889c06ea4b9e3520a63b2a0fcb6ee7defbc80050f7e3e10afde6729da036d67cdd1e4015d8a32e36e9183a0d7e872e1202860e5b9975ba22b53ccbc56b"
        
        XCTAssertEqual(toSendBytes, ethalonBytesToSend)
        XCTAssertEqual(toSendString, ethalonStringToSend)
    }
    
    func testSignToSend() {
        let androidStr = "00fb000073102091b4d142823f7d20c5f08df69122de43f35f057a988d9619f6d3138485c9a2030108bb0000000000002311202ac9a6746aca543af8dff39894cfe8173afba21eb01c6fae33d52947222855ef510120502025d23f994268f9b62144a7fc0c484c4a2e7cb656a3841aafe224318c4d9b0f86"
        
        let iosStr = "00fb000073102091b4d142823f7d20c5f08df69122de43f35f057a988d9619f6d3138485c9a2030108bb0000000000002311202ac9a6746aca543af8dff39894cfe8173afba21eb01c6fae33d52947222855ef510120502025d23f994268f9b62144a7fc0c484c4a2e7cb656a3841aafe224318c4d9b0f86"
        
        XCTAssertEqual(iosStr, androidStr)
    }
    
    func testHex() {
        
        let ethalonBytes = [0, -5, 0, 0, 115, 16, 32, -111, -76, -47, 66, -126, 63, 125, 32, -59, -16, -115, -10, -111, 34, -34, 67, -13, 95, 5, 122, -104, -115, -106, 25, -10, -45, 19, -124, -123, -55, -94, 3, 1, 8, -69, 0, 0, 0, 0, 0, 0, 35, 17, 32, 42, -55, -90, 116, 106, -54, 84, 58, -8, -33, -13, -104, -108, -49, -24, 23, 58, -5, -94, 30, -80, 28, 111, -82, 51, -43, 41, 71, 34, 40, 85, -17, 81, 1, 32, 80, 32, 37, -46, 63, -103, 66, 104, -7, -74, 33, 68, -89, -4, 12, 72, 76, 74, 46, 124, -74, 86, -93, -124, 26, -81, -30, 36, 49, -116, 77, -101, 15, -122].bytes
        
        let iosBytes = "00fb000073102091b4d142823f7d20c5f08df69122de43f35f057a988d9619f6d3138485c9a2030108bb0000000000002311202ac9a6746aca543af8dff39894cfe8173afba21eb01c6fae33d52947222855ef510120502025d23f994268f9b62144a7fc0c484c4a2e7cb656a3841aafe224318c4d9b0f86".asciiHexToData()!
        
        
        XCTAssertEqual(ethalonBytes, iosBytes)
    }
    
    func testEthFeeRequest() {
        let expectation = XCTestExpectation(description: "Fee loaded succesfully")
        let card = CardViewModel()
        card.walletPublicKey = "0x4dcc15cc2756d2b3b39c66c0a54d9265d8c386e0" //just dummy to avoid crash
        let ethEngine = ETHEngine(card: card)
        ethEngine.getFee(targetAddress: "0x4dcc15cc2756d2b3b39c66c0a54d9265d8c386e0", amount: "0.0001") { fee in
            
            guard let fee = fee else {
                XCTAssertNotNil(nil, "not loaded")
                return
            }
            print("min fee: \(fee.min) normal fee: \(fee.normal) max fee \(fee.max)")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 30.0)
    }
}
