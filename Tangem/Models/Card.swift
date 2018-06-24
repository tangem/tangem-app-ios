//
//  Card.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Yulia Moskaleva. All rights reserved.
//

import Foundation
struct Card {
    var CardID:String = ""
    var isWallet:Bool = false
    var Address:String = ""
    var BtcAddressTest:String = ""
    var BtcAddressMain:String = ""
    var EthAddress:String = ""
    var binaryAddress:String = ""
    var hexPublicKey:String = ""
    var Blockchain:String = ""
    var BlockchainName:String = ""
    var Issuer:String = ""
    var Manufacture_Date_Time:String = ""
    var RemainingSignatures: String = ""
    var type = ""
    var test = ""
    var mult = ""
    var WalletValue = "0.00"
    var WalletUnits = ""
    var USDWalletValue = ""
    var value:Int = 0
    var valueUInt64:UInt64 = 0
    var Link:String = ""
    var error:Int = 0
    var Node:String = ""
    var Salt:String = ""
    var Challenge:String = ""
    var signArr:[UInt8] = [UInt8]()
    var pubArr:[UInt8] = [UInt8]()
    var checked:Bool = false
    var checkedResult:Bool = true
    var checkedBalance:Bool = false
    
    //Ribbons vars
    var SignedHashes: String = ""
    var Firmware:String = "Not available"
    
    //Default value
    var ribbonCase:Int = 0
    /*
     1 - Firmware conteins simbol 'd'
     2 - Firmware conteins simbol 'r' and SignedHashes == ""
     3 - Firmware conteins simbol 'r' and SignedHashes <> ""
     4 - Virsion < 1.19 (Format firmware -  x.xx + любое кол-во других символов)
     */
    
    
    
    init() {}
}

struct Links {
    static let bitcoinMainLink = "https://blockchain.info/address/"
    static let bitcoinTestLink = "https://testnet.blockchain.info/address/"
    static let ethereumMainLink = "https://etherscan.io/address/"
    static let ethereumTestLink = "https://rinkeby.etherscan.io/address/"
}
