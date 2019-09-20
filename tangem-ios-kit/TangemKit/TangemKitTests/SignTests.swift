//
//  SignTests.swift
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

class SignTests: XCTestCase {
    func testCardBuilCommandApdu() {
        //Mark: Input
        
        let cardIdBytes: [UInt8] = "CB05000000040030".asciiHexToData()!
        let hashBytes: [UInt8] = "916E19992E7F9B1E8D9267C3324616DAC8F4199419C6E4EBF68FDA985F4B64EAFB8D8391FC40575DCA6D3C363BC46A3F64EBF484FBA9187CDF62AEE6CBCE6C1FD2A60F77213D0DBD109F34125031F04F216EDB400497FF3A8A60CFC8B9FA818B65D6DBDE870D6748711A34185851787D49879F34F46476B9EF551DC2A6F3B4EDAFE2A7945ED45FCD8D5103FCEE5343B87F044842491766D1810A00F9548E94FFCF34AAE21BEEBC83B4980296F074EA0D48EC49F5D547ABD5C3D5A090104409F08520EDACB060C65D4B071A2DEE677564DEC3FDBB8EBD6099F97A663FDE471B17FAAF1696A3087E6D51EBED35AD8606AB8CB90060BAA2A7654E4F5ABBAFED9BC1287DA32EC5EB11EFA2AF08C5D898A5F32BDEAD4C786A778A6F37BEFC4F445B11B93B3713B52B256D836D79A473FEFCAE970C384439BEE47C0A4FF9E7A73448E7".asciiHexToData()!
        let transactionOutHashSizeBytes: [UInt8] = [0x20]
        
         //Mark: Output
        let ethalonBytes: [UInt8] = "00FB0000000195102091B4D142823F7D20C5F08DF69122DE43F35F057A988D9619F6D3138485C9A2030108CB0500000004003011202AC9A6746ACA543AF8DFF39894CFE8173AFBA21EB01C6FAE33D52947222855EF51012050FF0140916E19992E7F9B1E8D9267C3324616DAC8F4199419C6E4EBF68FDA985F4B64EAFB8D8391FC40575DCA6D3C363BC46A3F64EBF484FBA9187CDF62AEE6CBCE6C1FD2A60F77213D0DBD109F34125031F04F216EDB400497FF3A8A60CFC8B9FA818B65D6DBDE870D6748711A34185851787D49879F34F46476B9EF551DC2A6F3B4EDAFE2A7945ED45FCD8D5103FCEE5343B87F044842491766D1810A00F9548E94FFCF34AAE21BEEBC83B4980296F074EA0D48EC49F5D547ABD5C3D5A090104409F08520EDACB060C65D4B071A2DEE677564DEC3FDBB8EBD6099F97A663FDE471B17FAAF1696A3087E6D51EBED35AD8606AB8CB90060BAA2A7654E4F5ABBAFED9BC1287DA32EC5EB11EFA2AF08C5D898A5F32BDEAD4C786A778A6F37BEFC4F445B11B93B3713B52B256D836D79A473FEFCAE970C384439BEE47C0A4FF9E7A73448E7".asciiHexToData()!
        
        let pin2Ethalon = "2AC9A6746ACA543AF8DFF39894CFE8173AFBA21EB01C6FAE33D52947222855EF"
        let pinEthalon = "91B4D142823F7D20C5F08DF69122DE43F35F057A988D9619F6D3138485C9A203"
      
        
        
        let pin2Sha = "000".sha256().uppercased()
        XCTAssertEqual(pin2Sha, pin2Ethalon)
        let pin2Bytes = pin2Sha.asciiHexToData()!
        
        
        let pinSha = "000000".sha256().uppercased()
        XCTAssertEqual(pinSha, pinEthalon)
        let pinBytes = pinSha.asciiHexToData()!
        
        let tlvData = [
            CardTLV(.pin, value: pinBytes),
            CardTLV(.cardId, value: cardIdBytes),
            CardTLV(.pin2, value: pin2Bytes),
            CardTLV(.transactionOutHashSize, value: transactionOutHashSizeBytes),
            CardTLV(.transactionOutHash, value: hashBytes)]
        
        let commandApdu = CommandApdu(with: .sign, tlv: tlvData)
        let bytes = commandApdu.buildCommand()

        
        XCTAssertEqual(bytes, ethalonBytes)
    }
    
    
    func testSWCombine() {
        let bytes = "1C02170C9789".asciiHexToData()!
        let responseApdu = try? ResponseApdu(with: bytes)
        let sw = responseApdu!.state
        
        XCTAssertTrue(sw == CardSW.needPause)
    }
    
    
    func testBuildResponseApdu() {
        let bytes = "1C02170C9789".asciiHexToData()!
        let responseApdu = try! ResponseApdu(with: bytes)
        
        let estimated = CardTLV(.pause, value: [UInt8(0x17), UInt8(0x0C)])
        let result = responseApdu.tlv.first!.value
        
        XCTAssertTrue(result.tag == estimated.tag)
        XCTAssertTrue(result.value! == estimated.value!)
    }
    
    func testIntFromBytes() {
        let bytes = [UInt8(11), UInt8(84)]
        let int = 2900
        
        let testInt = Int(from: bytes)
        
        XCTAssertEqual(int, testInt)
    }
}
 
