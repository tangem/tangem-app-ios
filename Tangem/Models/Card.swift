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
    case cle
    case qlear
    case ert
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
    var manufactureSignature: String = ""
    var batchId: Int = 0x0
    var remainingSignatures:  String = ""
    var type: WalletType {
        if blockchainName.containsIgnoringCase(find: "bitcoin") || blockchainName.containsIgnoringCase(find: "btc") {
            return .btc
        }
        
        if blockchainName.containsIgnoringCase(find: "eth") {
            switch tokenSymbol {
            case "SEED":
                return .seed
            case "QLEAR":
                return .qlear
            case "CLE":
                return .cle
            case "ERT":
                return .ert
            default:
                return .eth
            }
        }
        
        return .empty
    }
    var isTestNet = false
    var mult = ""
    
    var tokenSymbol: String = ""
    private var tokenContractAddressPrivate: String?
    var tokenContractAddress: String? {
        set {
            tokenContractAddressPrivate = newValue
        }
        get {
            if batchId == 0x0019 { // CLE
                return "0x0c056b0cda0763cc14b8b2d6c02465c91e33ec72"
            } else if batchId == 0x0017 { // Qlear
                return "0x9Eef75bA8e81340da9D8d1fd06B2f313DB88839c"
            }
            return tokenContractAddressPrivate
        }
    }
    var tokenDecimal: Int = 0
    
    var walletValue = "0.00"
    var walletUnits = ""
    var usdWalletValue = ""
    var value: Int = 0
    var valueUInt64: UInt64 = 0
    var link: String = ""
    var error: Int = 0
    var node: String = ""
    var salt: String?
    var challenge: String?
    var signArr: [UInt8] = [UInt8]()
    var pubArr: [UInt8] = [UInt8]()
    var checked: Bool = false
    var checkedResult: Bool = true
    var checkedBalance: Bool = false
    
    // Ribbons vars
    var signedHashes: String = ""
    var firmware: String = "Not available"
    
    // Default value
    var ribbonCase: Int = 0
    
    var imageName: String {
        switch batchId {
        case 0x0004:
            return "card-btc001"
        case 0x0005:
            return "card-btc005"
        case 0x0006:
            return "card-btc001"
        case 0x0007:
            return "card-btc005"
        case 0x0008, 0x0009:
            let index = cardID.index(cardID.endIndex, offsetBy: -4)
            guard let lastIndexDigits = Int(cardID[index...]) else {
                assertionFailure()
                return "card-default"
            }
            
            if lastIndexDigits < 5000 {
                return "card-btc001"
            } else {
                return "card-btc005"
            }
        case 0x0010:
            let cardIdWithoutSpaces = cardID.replacingOccurrences(of: " ", with: "")

            let index = cardIdWithoutSpaces.index(cardIdWithoutSpaces.endIndex, offsetBy: -5)
            if let lastIndexDigits = Int(cardIdWithoutSpaces[index...]), lastIndexDigits >= 25000, lastIndexDigits < 50000 {
                return "card-btc005"
            }

            return "card-btc001"
        case 0x0011:
            return "card-btc005"
        case 0x0012:
            return "card-seed"
        case 0x0013:
            return "card-bitcoinhk"
        case 0x0014:
            return "card-btc001"
        case 0x0015:
            return "card-btc000-silver"
        case 0x0016:
            return "card-eth000-silver"
        case 0x0017:
            return "card-qlear"
        case 0x0019:
            return "card-cyclebit"
        case 0x001A:
            return "card-btc000"
        case 0x001B:
            return "card-eth000"
        case 0x001C:
            return "card-coldlar-btc"
        case 0x001D:
            return "card-coldlar-eth"
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
