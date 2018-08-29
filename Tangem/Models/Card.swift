//
//  Card.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Yulia Moskaleva. All rights reserved.
//

import Foundation

enum WalletType {
    case btc
    case eth
    case seed
    case empty
}

struct Card {
    
    var cardID: String = ""
    var isWallet: Bool = false
    
    var address: String = ""
    var btcAddressTest: String = ""
    var btcAddressMain: String = ""
    var ethAddress: String = ""
    var binaryAddress: String = ""
    var hexPublicKey: String = ""
    
    var blockchain: String = ""
    var blockchainName: String = ""
    var issuer: String = ""
    var manufactureDateTime: String = ""
    var batchId: Int = 0x0
    var remainingSignatures:  String = ""
    var type: WalletType = .empty
    var isTestNet = false
    var mult = ""
    
    var tokenSymbol: String = ""
    var tokenContractAddress: String = ""
    var tokenDecimal: Int = 0
    
    var walletValue = "0.00"
    var walletUnits = ""
    var usdWalletValue = ""
    var value: Int = 0
    var valueUInt64: UInt64 = 0
    var link: String = ""
    var error: Int = 0
    var node: String = ""
    var salt: String = ""
    var challenge: String = ""
    var signArr: [UInt8] = [UInt8]()
    var pubArr: [UInt8] = [UInt8]()
    var checked: Bool = false
    var checkedResult: Bool = true
    var checkedBalance: Bool = false
    
    // Ribbons vars
    var signedHashes:  String = ""
    var firmware: String = "Not available"
    
    // Default value
    var ribbonCase: Int = 0
    
    var imageName: String {
        switch batchId {
        case 0x0004:
            return "card-btc001"
        case 0x0010:
            return "card-btc005"
        case 0x0012:
            return "card-seed"
        case 0x0017:
            return "card-qlean"
        case 0x0019:
            return "card-cyclebit"
        default:
            return "card-default"
        }
    }
    
    /*
     1 - Firmware contains simbol 'd'
     2 - Firmware contains simbol 'r' and SignedHashes == ""
     3 - Firmware contains simbol 'r' and SignedHashes <> ""
     4 - Version < 1.19 (Format firmware -  x.xx + любое кол-во других символов)
     */
}

struct Links {
    static let bitcoinMainLink = "https://blockchain.info/address/"
    static let bitcoinTestLink = "https://testnet.blockchain.info/address/"
    static let ethereumMainLink = "https://etherscan.io/address/"
    static let ethereumTestLink = "https://rinkeby.etherscan.io/address/"
}
