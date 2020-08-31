//
//  Card.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Smart Cash AG. All rights reserved.
//

import Foundation
import GBAsyncOperation
import TangemSdk

public enum CardGenuinityState {
    case pending
    case genuine
    case nonGenuine
}

public enum Blockchain: String {
    case bitcoin
    case ethereum
    case rootstock
    case cardano
    case cardanoShelley
    case xrpl
    case binance
    case unknown
    case stellar
    case bitcoinCash
    case litecoin
    case ducatus
    
    public var decimalCount: Int16 {
        switch self {
        case .bitcoin, .bitcoinCash, .litecoin, .ducatus:
            return 8
        case .ethereum, .rootstock:
            return 18
        case .xrpl, .cardano, .cardanoShelley:
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
        case .cardano, .cardanoShelley:
            return .up
        case .ducatus:
            return .plain
        default:
            return .plain
        }
    }
}

public class CardViewModel {
    public let idIssuerKeys = [
        "04EAD74FEEE4061044F46B19EB654CEEE981E9318F0C8FE99AF5CDB9D779D2E52BB51EA2D14545E0B323F7A90CF4CC72753C973149009C10DB2D83DCEC28487729", //Sergio Mello
        "046D998FE88FB33A57404E152AF028DEDF6720A3FA6AAE630D51D31CA413C3E6BB1FC5CC53A9484D744EA2A1E6A3D6A88AC963F4D671887F939778B30A6146E7B0", //Regina Latypova
        "041DCEFEF8FA536EE746707E800400C61B7F87B1E06A58F1AA04B4C0E36DF445655A089C351AE670FA5778620F06624FB4014C1B07EB436B8D47186B063530B560"] //Alexander Osokin
    
    public var cardModel: Card
    public var cardEngine: CardEngine!
    public var issuerExtraData: ReadIssuerExtraDataResponse?
    public var status: CardStatus = .loaded
    public var productMask: ProductMask = ProductMask.note
    public var health = 0
    public var cardID: String = ""
    public var cardPublicKey: String = ""
    public var isWallet: Bool {
        return !walletPublicKey.isEmpty
    }
    
    public var address: String {
        return cardEngine.walletAddress
    }
    public var securityDelay: Int? = nil
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
         case let blockchainName where blockchainName.containsIgnoringCase(find: "cardano-s"):
            return .cardanoShelley
        case let blockchainName where blockchainName.containsIgnoringCase(find: "cardano"):
            return .cardano
        case let blockchainName where blockchainName.containsIgnoringCase(find: "XRP"):
            return .xrpl
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
        case let blockchainName where blockchainName.containsIgnoringCase(find: "duc"):
            return .ducatus
        default:
            return .unknown
        }
    }
    public var isBlockchainKnown: Bool {
        return blockchain != .unknown
    }
    
    public var isBalanceVerified: Bool = false
    public var hasAccount = true
    
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
    public var remainingSignatures: Int = -1
    
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
        return tokenSymbol
    }
    
    public var units: String {
        if let tokenValue = walletTokenValue, tokenValue != "0" {
            return walletTokenUnits ?? walletUnits
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
    
    public var hasEmptyWallet: Bool {
        if let total = Decimal(string: balance), total == 0, isWallet {
            return true
        } else {
          return false
        }
    }
    
    public var hasEnoughFee: Bool {
        if let total = Decimal(string: walletValue), total > 0 {
            return true
        } else {
            return false
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
    public let settingsMask: SettingsMask?
    
    /*
     1 - Firmware contains  'd'
     2 - Firmware contains simbol 'r' and SignedHashes == ""
     3 - Firmware contains simbol 'r' and SignedHashes <> ""
     4 - Version < 1.19 (Format firmware -  x.xx + любое кол-во других символов)
     */
    
    public var canExtract: Bool {
        guard blockchain == .bitcoin
            || blockchain == .ethereum
            || blockchain == .cardano
            || blockchain == .cardanoShelley
            || blockchain == .stellar
            || blockchain == .rootstock
            || blockchain == .binance
            || blockchain == .bitcoinCash
            || blockchain == .litecoin
            || blockchain == .ducatus
            || blockchain == .xrpl else {
                return false
        }
        
        if let securityDelay = securityDelay, securityDelay <= 1500 {
            return true
        }
        
        if batchId == 38 { //old cardano cards
            return true
        }
        
        return !isOldFw
    }
    
    public var isOldFw: Bool {
        let digits = firmware.remove("d SDK").remove("r").remove("\0")
        let ver = Decimal(string: digits) ?? 0
        return ver < 2.28
    }
    
    public let supportedSignMethods: SigningMethod?
    
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
        
        guard let image = UIImage(named: imageName, in: Bundle(for: CardViewModel.self), compatibleWith: nil) else {
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
        if productMask.contains(ProductMask.idIssuer) || idIssuerKeys.contains(walletPublicKey) {
            return "card-idIssuer"
        }
        
        if cardEngine.walletType == .nft {
            return "card-ruNFT"
        }
        
        if cardEngine.walletType == .slix2 {
            return "card_tgslix"
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
        case 0x0038:
            return "card-swisskey-btc"
        case 0x0039:
            return "card-swisskey-eth"
        case 0x0044:
            return "card-ducatus"
        case 0x0041, 0x0046:
            return "card_tg054"
        case 0x0042, 0x0047:
            return "card_tg055"
        case 0x0045:
            return "card_tg057"
        case 0x0049:
            return "card_tg060"
        case 0x0050:
            return "card_tg061"
        case 0x0051:
            return "card_tg062"
        case 0x0052:
            return "card_tg063"
        case 0x0060:
            return "card_tg073"
        default:
            return "card-default"
        }
    }
    public var qrCodeAddress: String {
        guard !address.isEmpty else {
            return ""
        }
        return cardEngine.qrCodePreffix + address
    }
    
    public init(_ card: Card) {
        self.cardModel = card
        cardID = card.cardId ?? ""
        cardPublicKey = card.cardPublicKey?.hex ?? ""
        firmware = card.firmwareVersion  ?? ""
        batchId =  Int(card.cardData?.batchId ?? "0x00", radix: 16) ?? -1
        manufactureDateTime = card.cardData?.manufactureDateTime?.toString() ?? ""
        issuer = card.cardData?.issuerName ?? ""
        manufactureId = card.manufacturerName ?? ""
        blockchainName = card.cardData?.blockchainName ?? ""
        tokenSymbol = card.cardData?.tokenSymbol
        tokenContractAddressPrivate = card.cardData?.tokenContractAddress
        tokenDecimal = card.cardData?.tokenDecimal
        manufactureSignature = card.cardData?.manufacturerSignature?.hex ?? ""
        walletPublicKey = card.walletPublicKey?.asHexString() ??  ""
        walletPublicKeyBytesArray = card.walletPublicKey?.bytes ?? []
        maxSignatures = "\(card.maxSignatures ?? -1)"
        remainingSignatures = card.walletRemainingSignatures ?? -1
        signedHashes = "\(card.walletSignedHashes ?? -1)"
        challenge = card.challenge?.hex.lowercased()
        salt = card.salt?.hex.lowercased()
        signArr = card.walletSignature?.bytes ?? []
        status = card.status ?? CardStatus.empty
        issuerDataPublicKey = card.issuerPublicKey?.bytes ?? []
        health = card.health ?? 0
        productMask = card.cardData?.productMask ?? ProductMask.note
        cardIdSignedByManufacturer = card.cardData?.manufacturerSignature?.bytes ?? []
        supportedSignMethods = card.signingMethods
        curve = card.curve
        settingsMask = card.settingsMask
        isLinked = card.terminalIsLinked
        securityDelay = card.pauseBeforePin2
        setupEngine()
    }
    
    public func updateCard(_ card: Card) {
        self.cardModel = card
        remainingSignatures = card.walletRemainingSignatures ?? -1
    }
    
    public func setupWallet(status: CardStatus, walletPublicKey: Data?) {
        self.status = status
        self.walletPublicKey = walletPublicKey?.hex ?? ""
        self.walletPublicKeyBytesArray = walletPublicKey?.bytes ?? []
        setupEngine()
    }
    //    //[REDACTED_TODO_COMMENT]
    //    public init(tags: [CardTLV]) {
    //        tags.forEach({
    //            switch $0.tag {
    //            case .cardId:
    //                cardID = $0.value?.hexString.cardFormatted ?? ""
    //            case .cardPublicKey:
    //                cardPublicKey = $0.value?.hexString ?? ""
    //            case .firmware:
    //                firmware = $0.value?.utf8String ?? ""
    //            case .batch:
    //                batchId = $0.value?.intValue ?? -1 //Int($0.hexStringValue, radix: 16)!
    //            case .manufactureDateTime:
    //                manufactureDateTime = $0.value?.dateString ?? ""
    //            case .issuerId:
    //                issuer = $0.value?.utf8String ?? ""
    //            case .manufactureId:
    //                manufactureId = $0.value?.utf8String ?? ""
    //            case .blockchainId:
    //                blockchainName = $0.value?.utf8String ?? ""
    //            case .tokenSymbol:
    //                tokenSymbol = $0.value?.utf8String ?? ""
    //            case .tokenContractAddress:
    //                tokenContractAddress = $0.value?.utf8String ?? ""
    //            case .tokenDecimal:
    //                tokenDecimal = $0.value?.intValue ?? 0 // Int($0.hexStringValue, radix: 16)!
    //            case .manufacturerSignature:
    //                manufactureSignature = $0.value?.hexString ?? ""
    //            case .walletPublicKey:
    //                walletPublicKey = $0.value?.hexString ?? ""
    //                walletPublicKeyBytesArray = $0.value ?? []
    //            case .maxSignatures:
    //                maxSignatures = "\($0.value?.intValue ?? -1)"
    //            case .walletRemainingSignatures:
    //                remainingSignatures = "\($0.value?.intValue ?? -1)"
    //            case .walletSignedHashes:
    //                signedHashes = $0.value?.hexString ?? ""
    //            case .challenge:
    //                challenge = $0.value?.hexString.lowercased() ?? ""
    //            case .salt:
    //                salt = $0.value?.hexString.lowercased() ?? ""
    //            case .signature:
    //                signArr = $0.value ?? []
    //            case .status:
    //                let intStatus = $0.value?.intValue ?? 0
    //                status = CardStatus(rawValue: intStatus) ?? .loaded
    //            case .issuerDataPublicKey:
    //                issuerDataPublicKey = $0.value ?? []
    //            case .health:
    //                health = $0.value?.intValue ?? 0
    //            case .productMask:
    //                if let firstByte = $0.value?.first, let mask = ProductMask(rawValue: firstByte) {
    //                    productMask = mask
    //                }
    //            case .cardIDManufacturerSignature:
    //                cardIdSignedByManufacturer = $0.value ?? []
    //            case .signingMethod:
    //                if let intMethod = $0.value?.intValue {
    //
    //                    if ((intMethod & 0x80) != 0) {
    //                        for i in 0..<6  {
    //                            if ((intMethod & (0x01 << i)) != 0) {
    //                                if let method = SignMethod(rawValue: intMethod) {
    //                                    supportedSignMethods.append(method)
    //                                }
    //                            }
    //                        }
    //                    } else {
    //                        if let method = SignMethod(rawValue: intMethod) {
    //                            supportedSignMethods = [method]
    //                        }
    //                    }
    //                }
    //            case .curveId:
    //                if let curveId = $0.value?.utf8String {
    //                    curve = EllipticCurve(rawValue: curveId)
    //                }
    //            case .settingsMask:
    //                settingsMask = $0.value ?? []
    //            case .isLinked:
    //                isLinked = true
    //            default:
    //                if $0.tag != .cardData  {
    //                    print("Warning: Tag \($0.tag) doesn't have a handler in a Card class")
    //                }
    //            }
    //        })
    //
    //        setupEngine()
    //    }
    
    func setupEngine() {
        switch blockchain {
        case .bitcoin:
            cardEngine = BTCEngine(card: self)
        case .rootstock:
            cardEngine = RootstockEngine(card: self)
        case .cardano, .cardanoShelley:
            cardEngine = CardanoEngine(card: self)
        case .xrpl:
            cardEngine = RippleEngine(card: self)
        case .ethereum:
            if productMask.contains(.idCard) {
                cardEngine = ETHIdEngine(card: self)
                return
            }
            
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
        case .ducatus:
            cardEngine = DucatusEngine(card: self)
        default:
            cardEngine = NoWalletCardEngine(card: self)
        }
    }
    
    func updateWithVerificationCard(_ card: CardViewModel) {
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
    
    func invalidateSignedHashes(with card: CardViewModel) {
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

public extension CardViewModel {
    
    //    func signatureVerificationOperation(completion: @escaping (Bool) -> Void) throws -> GBAsyncOperation {
    //        guard let salt = salt, let challenge = challenge else {
    //            throw "parametersNil"
    //        }
    //
    //        return SignatureVerificationOperation(curve: curveID, saltHex: salt, challengeHex: challenge, signatureArr: signArr, publicKeyArr: walletPublicKeyBytesArray) { (isGenuineCard) in
    //            completion(isGenuineCard)
    //        }
    //    }
    
    func balanceRequestOperation(onSuccess: @escaping (CardViewModel) -> Void, onFailure: @escaping (Error, String?) -> Void) -> GBAsyncOperation? {
        var operation: GBAsyncOperation?
        
        let onResult = { (result: TangemKitResult<CardViewModel>) in            
            DispatchQueue.main.async {
                switch result {
                case .success(let card):
                    onSuccess(card)
                case .failure(let error, let title):
                    onFailure(error, title)
                }
            }
        }
        
        switch blockchain {
        case .bitcoin:
            operation = BTCCardBalanceOperation(card: self, completion: onResult)
        case .ethereum:
            if productMask.contains(.idCard) {
                return ETHIdCardBalanceOperation(card: self, networkUrl: TokenNetwork.eth.rawValue, completion: onResult)
            }            
            if tokenSymbol != nil {
                operation = TokenCardBalanceOperation(card: self, completion: onResult)
            } else {
                operation = ETHCardBalanceOperation(card: self, networkUrl: isTestBlockchain ? TokenNetwork.ethTest.rawValue : TokenNetwork.eth.rawValue, completion: onResult)
            }
        case .rootstock:
            let rskOperation = RSKCardBalanceOperation(card: self, completion: onResult)
            rskOperation.hasToken = tokenContractAddress != nil
            operation = rskOperation
        case .cardano, .cardanoShelley:
            operation = CardanoCardBalanceOperation(card: self, completion: onResult)
        case .xrpl:
            operation = XRPCardBalanceOperation(card: self, completion: onResult)
        case .binance:
            operation = BNBCardBalanceOperation(card: self, completion: onResult)
        case .stellar:
            operation = XlmCardBalanceOperation(card: self, isAsset: tokenSymbol != nil, completion: onResult)
        case .bitcoinCash:
            operation = BCHCardBalanceOperation(card: self, completion: onResult)
        case .ducatus:
            operation = DucatusCardBalanceOperation(card: self, completion: onResult)
        case .litecoin:
            let op = BTCCardBalanceOperation(card: self, completion: onResult)
            op.blockcypherAPi = .ltc
            return op
        default:
            break
        }
        
        return operation
    }
    
   func getIdData() -> IdCardData? {
        if let data = issuerExtraData?.issuerData {
            return IdCardData(data)
        }
        return nil
    }
    
    var moreInfoData: String {
        var strings = ["\(Localizations.detailsCategoryIssuer): \(issuer)",
            "\(Localizations.detailsCategoryManufacturer): \(manufactureName)",
            "\(Localizations.detailsRegistrationDate): \(manufactureDateTime)"]
        
        let sigs = remainingSignatures == -1 ? "" : "\(remainingSignatures)"
        
        if type != .slix2 {
            strings.append("\(Localizations.detailsFirmware): \(firmware)")
            strings.append("\(Localizations.detailsRemainingSignatures): \(sigs)")
            strings.append("\(Localizations.detailsTitleCardId): \(cardID)")
        }
        
        if #available(iOS 13.0, *) {} else {
            var cardChallenge: String? = nil
            if let challenge = challenge, let saltValue = salt {
                let cardChallenge1 = String(challenge.prefix(3))
                let cardChallenge2 = String(challenge[challenge.index(challenge.endIndex,offsetBy:-3)...])
                let cardChallenge3 = String(saltValue.prefix(3))
                let cardChallenge4 = String(saltValue[saltValue.index(saltValue.endIndex,offsetBy:-3)...])
                cardChallenge = [cardChallenge1, cardChallenge2, cardChallenge3, cardChallenge4].joined(separator: " ")
            }
            
            var verificationChallenge: String? = nil
            if let challenge = verificationChallenge, let saltValue = verificationSalt {
                let cardChallenge1 = String(challenge.prefix(3))
                let cardChallenge2 = String(challenge[challenge.index(challenge.endIndex,offsetBy:-3)...])
                let cardChallenge3 = String(saltValue.prefix(3))
                let cardChallenge4 = String(saltValue[saltValue.index(saltValue.endIndex,offsetBy:-3)...])
                verificationChallenge = [cardChallenge1, cardChallenge2, cardChallenge3, cardChallenge4].joined(separator: " ")
            }
            
            strings.append("\(Localizations.challenge) 1: \(cardChallenge ?? Localizations.notAvailable)")
            strings.append("\(Localizations.challenge) 2: \(verificationChallenge ?? Localizations.notAvailable)")
        }
        
        if isLinked {
            strings.append(Localizations.detailsLinkedCard)
        }
        
        return strings.joined(separator: "\n")
    }
}
