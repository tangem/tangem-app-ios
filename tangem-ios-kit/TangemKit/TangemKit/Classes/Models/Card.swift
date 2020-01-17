//
//  Card.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Smart Cash AG. All rights reserved.
//

import Foundation
import GBAsyncOperation

public enum SignMethod: Int{
    case signHash = 0
    case signRaw = 1
    case signHashValidatedByIssuer = 2
    case signRawValidatedByIssuer = 3
    case signHashValidatedByIssuerAndWriteIssuerData = 4
    case SignRawValidatedByIssuerAndWriteIssuerData = 5
    case signPos = 6
}

public enum CardGenuinityState {
    case pending
    case genuine
    case nonGenuine
}

public enum EllipticCurve: String {
    case secp256k1
    case ed25519
}

public enum CardStatus: Int {
    case notPersonalized = 0
    case empty = 1
    case loaded = 2
    case purged = 3
}

public enum ProductMask: UInt8 {
    case note = 0x01
    case tag = 0x02
    case idCard = 0x04
}

public enum Blockchain: String {
    case bitcoin
    case ethereum
    case rootstock
    case cardano
    case ripple
    case binance
    case unknown
    case stellar
    case bitcoinCash
    case litecoin
    
    public var decimalCount: Int16 {
        switch self {
        case .bitcoin, .bitcoinCash, .litecoin:
            return 8
        case .ethereum, .rootstock:
            return 18
        case .ripple, .cardano:
            return 6
        case .binance:
            return 8
        case .stellar:
            return 7
        default:
            assertionFailure()
            return 0
        }
    }
    
    public var roundingMode: NSDecimalNumber.RoundingMode {
        switch self {
        case .bitcoin, .ethereum, .rootstock, .binance, .bitcoinCash, .litecoin:
            return .down
        case .cardano:
            return .up
        default:
            return .plain
        }
    }
}

public class Card {
    
    public var cardEngine: CardEngine!
    
    public var status: CardStatus = .loaded
    public var productMask: ProductMask = .note
    public var health = 0
    public var cardID: String = ""
    public var cardPublicKey: String = ""
    public var isWallet: Bool {
        return !walletPublicKey.isEmpty
    }
    
    public var address: String {
        return cardEngine.walletAddress
    }
    
    public var binaryAddress: String = ""
    public var isLinked = false
    public var walletPublicKey: String = ""
    public var walletPublicKeyBytesArray: [UInt8] = [UInt8]()
    public var issuerDataPublicKey: [UInt8] = [UInt8]()
    public var cardIdSignedByManufacturer: [UInt8] = [UInt8]()
    public var isTestBlockchain: Bool {
        return blockchainName.containsIgnoringCase(find: "test")
    }
    public var blockchainName: String = ""
    
    public var hasPendingTransactions: Bool {
        return (cardEngine as? CoinProvider)?.hasPendingTransactions ?? false
    }
    
    public var blockchain: Blockchain {
        guard blockchainName != "CARDANO:NB" else {
            return .unknown
        }
        
        switch blockchainName {
        case let blockchainName where (blockchainName.containsIgnoringCase(find: "bitcoin") || blockchainName.containsIgnoringCase(find: "btc")):
            return .bitcoin
        case let blockchainName where blockchainName.containsIgnoringCase(find: "rsk"):
            return .rootstock
        case let blockchainName where blockchainName.containsIgnoringCase(find: "cardano"):
            return .cardano
        case let blockchainName where blockchainName.containsIgnoringCase(find: "XRP"):
            return .ripple
        case let blockchainName where blockchainName.containsIgnoringCase(find: "eth"):
            return .ethereum
        case let blockchainName where blockchainName.containsIgnoringCase(find: "binance"):
            return .binance
        case let blockchainName where blockchainName.containsIgnoringCase(find: "xlm"):
            return .stellar
        case let blockchainName where blockchainName.containsIgnoringCase(find: "bch"):
            return .bitcoinCash
        case let blockchainName where blockchainName.containsIgnoringCase(find: "ltc"):
            return .litecoin
        default:
            return .unknown
        }
    }
    public var isBlockchainKnown: Bool {
        return blockchain != .unknown
    }
    
    private var curve: EllipticCurve?
    
    public var curveID: EllipticCurve {
        return curve ?? (walletPublicKeyBytesArray.count == 65 ? .secp256k1 : .ed25519)
    }
    
    public var issuer: String = ""
    public var manufactureId: String = ""
    
    public var manufactureName: String {
        guard !manufactureId.isEmpty else {
            return issuer
        }
        
        return manufactureId
            .replacingOccurrences(of: "SMART CASH", with: "TANGEM")
            .replacingOccurrences(of: "DEVELOP CASH AG", with: "TANGEM AG (DEVELOPERS)")
    }
    
    public var manufactureDateTime: String = ""
    public var manufactureSignature: String = ""
    public var batchId: Int = 0x0
    public var remainingSignatures: String = ""
    
    public var mult: Double = 0
    
    public var tokenSymbol: String?
    public var tokenDecimal: Int?
    
    public var type: WalletType {        
        return cardEngine.walletType
    }
    public var walletUnits: String {
        return cardEngine.walletUnits
    }
    public var walletTokenUnits: String? {
        if let tokenEngine = cardEngine as? TokenEngine {
            return tokenEngine.walletTokenUnits
        }
        return nil
    }
    
    public var units: String {
        if let tokenValue = walletTokenValue, tokenValue != "0" {
            return (walletTokenUnits ?? tokenSymbol) ?? walletUnits
        } else {
            return walletUnits
        }
    }
    
    public var balance: String {
        if let tokenValue = walletTokenValue, tokenValue != "0" {
            return tokenValue
        } else {
            return walletValue
        }
    }
    
    public var walletValue: String = "0"
    public var walletTokenValue: String?
    public var usdWalletValue: String?
    
    public var node: String = ""
    
    public var challenge: String?
    public var verificationChallenge: String?
    public var salt: String?
    public var verificationSalt: String?
    public var signArr: [UInt8] = [UInt8]()
    
    public var genuinityState: CardGenuinityState = .pending
    public var isAuthentic: Bool {
        return genuinityState == .genuine
    }
    
    public var maxSignatures: String?
    
    public var signedHashes: String = ""
    public var firmware: String = "Not available"
    
    public var ribbonCase: Int = 0
    public var settingsMask: [UInt8] = []
    
    /*
     1 - Firmware contains  'd'
     2 - Firmware contains simbol 'r' and SignedHashes == ""
     3 - Firmware contains simbol 'r' and SignedHashes <> ""
     4 - Version < 1.19 (Format firmware -  x.xx + любое кол-во других символов)
     */
    
    public var canExtract: Bool {
        if batchId == 38 { //old cardano cards
            return true
        }
        
        let digits = firmware.remove("d SDK").remove("r").remove("\0")
        let ver = Decimal(string: digits) ?? 0
        return ver >= 2.28 && (blockchain == .bitcoin || blockchain == .ethereum
            || blockchain == .cardano || blockchain == .stellar || blockchain == .rootstock || blockchain == .binance || blockchain == .bitcoinCash || blockchain == .litecoin)
    }
    
    public var supportedSignMethods: [SignMethod] = [.signHash]
    
    private var tokenContractAddressPrivate: String?
    public var tokenContractAddress: String? {
        set {
            tokenContractAddressPrivate = newValue
        }
        get {
            switch batchId {
            case 0x0019: // CLE
                return "0x0c056b0cda0763cc14b8b2d6c02465c91e33ec72"
            case 0x0017: // Qlear
                return "0x9Eef75bA8e81340da9D8d1fd06B2f313DB88839c"
            case 0x001E: // Whirl
                return "0xc6e6fbec35c866b46bbb9d4f43bbfd205944f019"
            case 0x0020: // CNS
                return "0xe961e7c13538db076b2db273cf408e4d4150fd72"
            default:
                return tokenContractAddressPrivate
            }
        }
    }
    ///
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
    
    private var imageNameFromCardId: String? {
        let cardIdWithoutSpaces = cardID.replacingOccurrences(of: " ", with: "")
        
        if cardIdWithoutSpaces.lowercased().starts(with: "bc") {
            return "card_bc00"
        }
        
        switch cardIdWithoutSpaces {
        case "AA01000000000000"..."AA01000000004999",
             "AE01000000000000"..."AE01000000004999",
             "CB01000000000000"..."CB01000000009999",
             "CB02000000000000"..."CB02000000024999",
             "CB01000000020000"..."CB01000000039999",
             "CB05000010000000"..."CB05000010009999":
            return "card-btc001"
        case  "AA01000000005000"..."AA01000000009999",
              "AE01000000005000"..."AE01000000009999",
              "CB01000000010000"..."CB01000000019999",
              "CB01000000040000"..."CB01000000059999",
              "CB02000000025000"..."CB02000000049999":
            return  "card-btc005"
        case "CB25000000000000"..."CB25000000099999":
            return "card_ru043"
        case "CB26000000000000"..."CB26000000099999":
            return "card_tg044"
        default: return nil
        }
    }
    
    var imageName: String {        
        if cardEngine.walletType == .nft {
            return "card-ruNFT"
        }
        
        if cardEngine.walletType == .slix2 {
            return "card-ruNFT"
        }
        
        if let nameFromCardId = imageNameFromCardId {
            return nameFromCardId
        }
        
        switch batchId {
        case 0x0004:
            return "card-btc001"
        case 0x0005:
            return "card-btc005"
        case 0x0006:
            return "card-btc001"
        case 0x0007:
            return "card-btc005"
        case 0x0010:
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
        case 0x0025:
            return "card-ru037"
        case 0x0026:
            return "card-ru039"
        case 0x0027:
            return "card_ru038"
        case 0x0030:
            return "card_ru038"
        case 0x0028:
            return "card_ru040"
        case 0x0029:
            return "card_ru041"
        case 0x0031:
            return "card_ru042"
        case 0xFF32:
            return "card_ff32"
        case 0x0034:
            return "card-start2coin"
        case 0x0036:
            return "card-xlm"
        case 0x0037:
            return "card-nodl"
        default:
            return "card-default"
        }
    }
    public var qrCodeAddress: String {
        return cardEngine.qrCodePreffix + address
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
            case .manufactureId:
                manufactureId = $0.stringValue
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
                walletPublicKeyBytesArray = $0.hexBinaryValues
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
        
        setupEngine()
    }
    //[REDACTED_TODO_COMMENT]
    public init(tags: [CardTLV]) {
        tags.forEach({
            switch $0.tag {
            case .cardId:
                cardID = $0.value?.hexString.cardFormatted ?? ""
            case .cardPublicKey:
                cardPublicKey = $0.value?.hexString ?? ""
            case .firmware:
                firmware = $0.value?.utf8String ?? ""
            case .batch:
                batchId = $0.value?.intValue ?? -1 //Int($0.hexStringValue, radix: 16)!
            case .manufactureDateTime:
                manufactureDateTime = $0.value?.dateString ?? ""
            case .issuerId:
                issuer = $0.value?.utf8String ?? ""
            case .manufactureId:
                manufactureId = $0.value?.utf8String ?? ""
            case .blockchainId:
                blockchainName = $0.value?.utf8String ?? ""
            case .tokenSymbol:
                tokenSymbol = $0.value?.utf8String ?? ""
            case .tokenContractAddress:
                tokenContractAddress = $0.value?.utf8String ?? ""
            case .tokenDecimal:
                tokenDecimal = $0.value?.intValue ?? 0 // Int($0.hexStringValue, radix: 16)!
            case .manufacturerSignature:
                manufactureSignature = $0.value?.hexString ?? ""
            case .walletPublicKey:
                walletPublicKey = $0.value?.hexString ?? ""
                walletPublicKeyBytesArray = $0.value ?? []
            case .maxSignatures:
                maxSignatures = "\($0.value?.intValue ?? -1)"
            case .walletRemainingSignatures:
                remainingSignatures = "\($0.value?.intValue ?? -1)"
            case .walletSignedHashes:
                signedHashes = $0.value?.hexString ?? ""
            case .challenge:
                challenge = $0.value?.hexString.lowercased() ?? ""
            case .salt:
                salt = $0.value?.hexString.lowercased() ?? ""
            case .signature:
                signArr = $0.value ?? []
            case .status:
                let intStatus = $0.value?.intValue ?? 0
                status = CardStatus(rawValue: intStatus) ?? .loaded
            case .issuerDataPublicKey:
                issuerDataPublicKey = $0.value ?? []
            case .health:
                health = $0.value?.intValue ?? 0
            case .productMask:
                if let firstByte = $0.value?.first, let mask = ProductMask(rawValue: firstByte) {
                    productMask = mask
                }
            case .cardIDManufacturerSignature:
                cardIdSignedByManufacturer = $0.value ?? []
            case .signingMethod:
                if let intMethod = $0.value?.intValue {
                    
                    if ((intMethod & 0x80) != 0) {
                        for i in 0..<6  {
                            if ((intMethod & (0x01 << i)) != 0) {
                                if let method = SignMethod(rawValue: intMethod) {
                                    supportedSignMethods.append(method)
                                }
                            }
                        }
                    } else {
                        if let method = SignMethod(rawValue: intMethod) {
                            supportedSignMethods = [method]
                        }
                    }
                }
            case .curveId:
                if let curveId = $0.value?.utf8String {
                    curve = EllipticCurve(rawValue: curveId)
                }
            case .settingsMask:
                settingsMask = $0.value ?? []
            case .isLinked:
                isLinked = true
            default:
                if $0.tag != .cardData  {
                    print("Warning: Tag \($0.tag) doesn't have a handler in a Card class")
                }
            }
        })
        
        setupEngine()
    }
    
    func setupEngine() {
        switch blockchain {
        case .bitcoin:
            cardEngine = BTCEngine(card: self)
        case .rootstock:
            cardEngine = RootstockEngine(card: self)
        case .cardano:
            cardEngine = CardanoEngine(card: self)
        case .ripple:
            cardEngine = RippleEngine(card: self)
        case .ethereum:
            if tokenSymbol != nil {
                cardEngine = TokenEngine(card: self)
            } else {
                cardEngine = ETHEngine(card: self)
            }
        case .binance:
            cardEngine = BinanceEngine(card: self)
        case .stellar:
            cardEngine = XlmEngine(card: self)
        case .bitcoinCash:
            cardEngine = BCHEngine(card: self)
        case .litecoin:
            cardEngine = LTCEngine(card: self)
        default:
            cardEngine = NoWalletCardEngine(card: self)
        }
    }
    
    func updateWithVerificationCard(_ card: Card) {
        genuinityState = .nonGenuine
        
        guard  card.isWallet else {
            return
        }
        
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
    
    func invalidateSignedHashes(with card: Card) {
        guard card.isWallet else {
            return
        }
        
        let currentSignedHashes = Int(signedHashes, radix: 16) ?? 0
        let secondReadSignedHashes = Int(card.signedHashes, radix: 16) ?? 0
        if secondReadSignedHashes > currentSignedHashes {
            signedHashes = card.signedHashes
        }
    }
    
    func substituteDataFrom(_ substitutionInfo: CardNetworkDetails) {
        guard let substutionData = substitutionInfo.substitution?.substutionData else {
            return
        } 
        
        if tokenSymbol == nil, let tokenSymbol = substutionData.tokenSymbol {
            self.tokenSymbol = tokenSymbol
            setupEngine()
        }
        if tokenContractAddress == nil, let tokenContractAddress = substutionData.tokenContractAddress {
            self.tokenContractAddress = tokenContractAddress
        }
        if tokenDecimal == nil, let tokenDecimal = substutionData.tokenDecimal {
            self.tokenDecimal = tokenDecimal
        }
    }
    
}

public extension Card {
    
    func signatureVerificationOperation(completion: @escaping (Bool) -> Void) throws -> GBAsyncOperation {
        guard let salt = salt, let challenge = challenge else {
            throw "parametersNil"
        }
        
        return SignatureVerificationOperation(curve: curveID, saltHex: salt, challengeHex: challenge, signatureArr: signArr, publicKeyArr: walletPublicKeyBytesArray) { (isGenuineCard) in
            completion(isGenuineCard)
        }
    }
    
    func balanceRequestOperation(onSuccess: @escaping (Card) -> Void, onFailure: @escaping (Error) -> Void) -> GBAsyncOperation? {
        var operation: GBAsyncOperation?
        
        let onResult = { (result: TangemKitResult<Card>) in            
            DispatchQueue.main.async {
                switch result {
                case .success(let card):
                    onSuccess(card)
                case .failure(let error):
                    onFailure(error)
                }
            }
        }
        
        switch blockchain {
        case .bitcoin:
            operation = BTCCardBalanceOperation(card: self, completion: onResult)
        case .ethereum:
            if tokenSymbol != nil {
                operation = TokenCardBalanceOperation(card: self, completion: onResult)
            } else {
                operation = ETHCardBalanceOperation(card: self, networkUrl: TokenNetwork.eth.rawValue, completion: onResult)
            }
        case .rootstock:
            let rskOperation = RSKCardBalanceOperation(card: self, completion: onResult)
            rskOperation.hasToken = tokenContractAddress != nil
            operation = rskOperation
        case .cardano:
            operation = CardanoCardBalanceOperation(card: self, completion: onResult)
        case .ripple:
            operation = XRPCardBalanceOperation(card: self, completion: onResult)
        case .binance:
            operation = BNBCardBalanceOperation(card: self, completion: onResult)
        case .stellar:
            operation = XlmCardBalanceOperation(card: self, completion: onResult)
        case .bitcoinCash:
            operation = BCHCardBalanceOperation(card: self, completion: onResult)
        case .litecoin:
            let op = BTCCardBalanceOperation(card: self, completion: onResult)
            op.blockcypherAPi = .ltc
            return op
        default:
            break
        }
        
        return operation
    }
    
}
