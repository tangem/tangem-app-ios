//
//  Card.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Smart Cash AG. All rights reserved.
//

import Foundation

struct Links {
    static let bitcoinMainLink = "https://blockchain.info/address/"
    static let bitcoinTestLink = "https://testnet.blockchain.info/address/"
    static let ethereumMainLink = "https://etherscan.io/address/"
    static let ethereumTestLink = "https://rinkeby.etherscan.io/address/"
}

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
    var isWallet = false
    
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
    
    var isTestNet = false
    var mult: Double = 0
    
    var tokenSymbol: String = ""
    
    var tokenDecimal: Int = 0
    
    var walletUnits = ""
    var walletValue = "0.00" // [REDACTED_TODO_COMMENT]
    var usdWalletValue = "" // [REDACTED_TODO_COMMENT]

    var value: Int = 0
    var valueUInt64: UInt64 = 0
    var link: String = ""

    var node: String = ""
    var salt: String?
    var challenge: String?
    var verificationChallenge: String?
    var signArr: [UInt8] = [UInt8]()
    var pubArr: [UInt8] = [UInt8]()
    
    var isAuthentic: Bool {
        guard let challenge = challenge, let verificationChallenge = verificationChallenge else {
            return false
        }
        return challenge != verificationChallenge
    }
    
    var maxSignatures: String?
    
    var signedHashes: String = ""
    var firmware: String = "Not available"
    
    var ribbonCase: Int = 0
    
    /*
     1 - Firmware contains simbol 'd'
     2 - Firmware contains simbol 'r' and SignedHashes == ""
     3 - Firmware contains simbol 'r' and SignedHashes <> ""
     4 - Version < 1.19 (Format firmware -  x.xx + любое кол-во других символов)
     */
    
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
    
    init() {
        self.init(tags: [TLV]())
    }
    
    init(tags: [TLV]) {
        tags.forEach({
            switch $0.tagName {
            case .cardId:
                cardID = $0.stringValue
            case .firmware:
                firmware = $0.stringValue
            case .batchId:
                batchId = Int($0.hexStringValue, radix: 16)!
            case .manufacturerDateTime:
                manufactureDateTime = $0.stringValue
            case .issuerName:
                issuer = $0.stringValue
            case .blockchainName:
                blockchainName = $0.stringValue
            case .tokenSymbol:
                tokenSymbol = $0.stringValue
            case .tokenContractAddress:
                tokenContractAddress = $0.stringValue
            case .tokenDecimal:
                tokenDecimal = Int($0.hexStringValue, radix: 16)!
            case .manufacturerSignature:
                manufactureSignature = $0.hexStringValue
            case .walletPublicKey:
                isWallet = true
                hexPublicKey = $0.hexStringValue
                pubArr = $0.hexBinaryValues
            case .maxSignatures:
                maxSignatures = $0.stringValue
            case .remainingSignatures:
                remainingSignatures = $0.stringValue
            case .signedHashes:
                signedHashes = $0.hexStringValue
            case .challenge:
                challenge = $0.hexStringValue.lowercased()
            case .salt:
                salt = $0.hexStringValue.lowercased()
            case .walletSignature:
                signArr = $0.hexBinaryValues

            case .health, .cardPublicKey, .settingsMask:
                break
                
            default:
                assertionFailure("Tag \($0) doesn't have a handler")
            }
        })
        
        setupAddress()
    }
    
    mutating func setupAddress() {
        if type == .btc {
            setupBTCAddress()
        } else {
            setupETHAddress()
        }
    }
    
    mutating func setupBTCAddress() {
        blockchain = "Bitcoin"
        node = randomNode()
        if blockchainName.containsIgnoringCase(find: "test"){
            isTestNet = true
            blockchain = "Bitcoin TestNet"
            node = randomTestNode()
        }
        if let addr = getAddress(hexPublicKey) {
            btcAddressMain = addr[0]
            btcAddressTest = addr[1]
        }
        walletUnits = "BTC"
        if !isTestNet {
            address = btcAddressMain
            link = Links.bitcoinMainLink + address
        } else {
            address = btcAddressTest
            link = Links.bitcoinTestLink + address
        }
    }
    
    mutating func setupETHAddress() {
        blockchain = "Ethereum"
        node = "mainnet.infura.io"
        if blockchainName.containsIgnoringCase(find: "test"){
            isTestNet = true
            blockchain = "Ethereum Rinkeby"
            node = "rinkeby.infura.io"
        }
        ethAddress = getEthAddress(hexPublicKey)
        walletUnits = tokenSymbol.isEmpty ? "ETH" : tokenSymbol
        address = ethAddress
        if !isTestNet {
            link = Links.ethereumMainLink + address
        } else {
            link = Links.ethereumTestLink + address
        }
    }
    
}
