//
//  Card.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Smart Cash AG. All rights reserved.
//

import Foundation
import GBAsyncOperation

struct Links {
    static let bitcoinMainLink = "https://blockchain.info/address/"
    static let ethereumMainLink = "https://etherscan.io/address/"
    static let rootstockExploreLink = "https://explorer.rsk.co/address/"
}

public enum WalletType {
    case btc
    case eth
    case seed
    case cle
    case qlear
    case ert
    case wrl
    case rsk
    case empty
}

public enum CardGenuinityState {
    case pending
    case genuine
    case nonGenuine
}

public class Card {

    public var cardID: String = ""
    public var cardPublicKey: String = ""
    public var isWallet: Bool {
        return !walletPublicKey.isEmpty
    }

    public var address: String = ""

    public var btcAddressMain: String = ""
    public var ethAddress: String = ""
    public var binaryAddress: String = ""
    public var walletPublicKey: String = ""

    public var blockchainDisplayName: String = ""
    public var blockchainName: String = ""
    public var issuer: String = ""
    public var manufactureDateTime: String = ""
    public var manufactureSignature: String = ""
    public var batchId: Int = 0x0
    public var remainingSignatures: String = ""

    public var mult: Double = 0

    public var tokenSymbol: String?
    public var tokenDecimal: Int?

    public var walletUnits: String {
        if type == .btc {
            return "BTC"
        } else {
            return tokenSymbol ?? "ETH"
        }
    }
    public var walletValue = "0.00" // [REDACTED_TODO_COMMENT]
    public var usdWalletValue = "" // [REDACTED_TODO_COMMENT]

    public var value: Int = 0
    public var valueUInt64: UInt64 = 0
    public var link: String = ""

    public var node: String = ""

    public var challenge: String?
    public var verificationChallenge: String?
    public var salt: String?
    public var verificationSalt: String?
    public var signArr: [UInt8] = [UInt8]()
    public var pubArr: [UInt8] = [UInt8]()

    public var genuinityState: CardGenuinityState = .pending
    public var isAuthentic: Bool {
        return genuinityState == .genuine
    }

    public var maxSignatures: String?

    public var signedHashes: String = ""
    public var firmware: String = "Not available"

    public var ribbonCase: Int = 0

    /*
     1 - Firmware contains simbol 'd'
     2 - Firmware contains simbol 'r' and SignedHashes == ""
     3 - Firmware contains simbol 'r' and SignedHashes <> ""
     4 - Version < 1.19 (Format firmware -  x.xx + любое кол-во других символов)
     */

    public var type: WalletType {
        if blockchainName.containsIgnoringCase(find: "bitcoin") || blockchainName.containsIgnoringCase(find: "btc") {
            return .btc
        }
        
        if blockchainName.containsIgnoringCase(find: "rsk") {
            return .rsk
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
            case "WRL":
                return .wrl
            default:
                return .eth
            }
        }

        return .empty
    }

    private var tokenContractAddressPrivate: String?
    public var tokenContractAddress: String? {
        set {
            tokenContractAddressPrivate = newValue
        }
        get {
            if batchId == 0x0019 { // CLE
                return "0x0c056b0cda0763cc14b8b2d6c02465c91e33ec72"
            } else if batchId == 0x0017 { // Qlear
                return "0x9Eef75bA8e81340da9D8d1fd06B2f313DB88839c"
            } else if batchId == 0x001E { // Whirl
                return "0xc6e6fbec35c866b46bbb9d4f43bbfd205944f019"
            } else if batchId == 0x0020 { // CNS
                return "0xe961e7c13538db076b2db273cf408e4d4150fd72"
            }
            return tokenContractAddressPrivate
        }
    }

    var substitutionImage: UIImage?
    public var image: UIImage? {
        if substitutionImage != nil {
            return substitutionImage
        }
        
        guard let image = UIImage(named: imageName, in: Bundle(for: Card.self), compatibleWith: nil) else {
            assertionFailure()
            return nil
        }

        return image
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
        case 0x0018:
            return "card-btc-18"
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
        case 0x001E:
            return "card-wrl"
        case 0x001F:
            return "card-btc-1F"
        case 0x0020:
            return "card-cns"
        case 0x0021:
            return "card-est"
        case 0x0022:
            return "card-btc-22"
        default:
            return "card-default"
        }
    }

    convenience init() {
        self.init(tags: [TLV]())
    }

    init(tags: [TLV]) {
        tags.forEach({
            switch $0.tagName {
            case .cardId:
                cardID = $0.stringValue
            case .cardPublicKey:
                cardPublicKey = $0.hexStringValue
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
                walletPublicKey = $0.hexStringValue
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

            case .health, .settingsMask:
                break

            default:
                print("Tag \($0.tagCode) doesn't have a handler")
            }
        })

        setupAddress()
    }

    public func setupAddress() {
        if type == .btc {
            setupBTCAddress()
        } else {
            setupETHAddress()
        }
    }

    private func setupBTCAddress() {
        blockchainDisplayName = "Bitcoin"
        node = randomNode()

        if let addr = AddressHelper.getBTCAddress(walletPublicKey) {
            btcAddressMain = addr[0]
        }
        address = btcAddressMain
        link = Links.bitcoinMainLink + address
    }

    private func setupETHAddress() {
        blockchainDisplayName = "Ethereum"
        node = "mainnet.infura.io"
        ethAddress = AddressHelper.getETHAddress(walletPublicKey)
        address = ethAddress
        link = Links.ethereumMainLink + address
    }
    
    private func setupRootstockAddress() {
        blockchainDisplayName = "Rootstock"
        node = "public-node.rsk.co"
        ethAddress = AddressHelper.getETHAddress(walletPublicKey)
        address = ethAddress
        link = Links.rootstockExploreLink + address
    }

    func updateWithVerificationCard(_ card: Card) {
        genuinityState = .nonGenuine

        guard let verificationChallenge = card.challenge, let verificationSalt = card.salt else {
            assertionFailure()
            return
        }
        self.verificationChallenge = verificationChallenge
        self.verificationSalt = verificationSalt

        guard let challenge = challenge, let salt = salt else {
            assertionFailure()
            return
        }

        if challenge != verificationChallenge && salt != verificationSalt {
            genuinityState = .genuine
        }

    }

}

public extension Card {

    public func signatureVerificationOperation(completion: @escaping (Bool) -> Void) throws -> GBAsyncOperation {
        guard let salt = salt, let challenge = challenge else {
            throw "parametersNil"
        }

        return SignatureVerificationOperation(saltHex: salt, challengeHex: challenge, signatureArr: signArr, publicKeyArr: pubArr) { (isGenuineCard) in
            completion(isGenuineCard)
        }
    }

    public func balanceRequestOperation(onSuccess: @escaping (Card) -> Void, onFailure: @escaping (Error) -> Void) -> GBAsyncOperation {
        var operation: GBAsyncOperation

        let onResult = { (result: TangemKitResult<Card>) in
            switch result {
            case .success(let card):
                onSuccess(card)
            case .failure:
                onFailure("getBalanceError")
            }
        }

        switch type {
        case .btc:
            operation = BTCCardBalanceOperation(card: self, completion: onResult)
        case .eth:
            operation = ETHCardBalanceOperation(card: self, completion: onResult)
        case .rsk:
            operation = RSKCardBalanceOperation(card: self, completion: onResult)
        default:
            operation = TokenCardBalanceOperation(card: self, completion: onResult)
        }

        return operation
    }

}
