//
//  Card+.swift
//  TangemClip
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdkClips
import BlockchainSdkClips

extension Card {
    var isTwinCard: Bool {
        cardData?.productMask?.contains(.twinCard) ?? false
    }
    
    var twinNumber: Int {
        TwinCardSeries.series(for: cardId)?.number ?? 0
    }
}

extension Card {
    var canSign: Bool {
//        let isPin2Default = self.isPin2Default ?? true
//        let hasSmartSecurityDelay = settingsMask?.contains(.smartSecurityDelay) ?? false
//        let canSkipSD = hasSmartSecurityDelay && !isPin2Default
        
        if let fw = firmwareVersionValue, fw < 2.28 {
            if let securityDelay = pauseBeforePin2, securityDelay > 1500 {
//                && !canSkipSD {
                return false
            }
        }
        
        return true
    }
    
    var isTestnet: Bool {
        false
    }
    
    var cardValidationData: (cid: String, pubKey: String)? {
        guard
            let cid = cardId,
            let pubKey = cardPublicKey?.asHexString()
        else { return nil }
        
        return (cid, pubKey)
    }
    
    var isStart2Coin: Bool {
        if let issuerName = cardData?.issuerName,
           issuerName.lowercased() == "start2coin" {
            return true
        }
        return false
    }
    
    var isMultiWallet: Bool {
        if isTwinCard {
            return false
        }
        
        if isStart2Coin {
            return false
        }
        
        if wallets.first?.curve != .secp256k1 {
            return false
        }
        
        return true
    }

}

extension Card {
    static var testCard: Card  = {
        return fromJson(testCardJson)
    }()
    
    private static func fromJson(_ json: String) -> Card {
        let jsonData = json.data(using: .utf8)!
        let decoder = JSONDecoder.tangemSdkDecoder
        do {
            let card = try decoder.decode(Card.self, from: jsonData)
            return card
        } catch {
            print(error)
        }
        fatalError()
    }
    
    private static let testCardJson =
        """
             {
               "cardData" : {
                 "batchId" : "FFFF",
                 "issuerName" : "TANGEM SDK",
                 "manufactureDateTime" : "Jan 9, 2021",
                 "manufacturerSignature" : "B906FA3D536BEFA41D7425D2FC3E96B6231FC6B50D6B50318A2E95DD39C621E11E9E3EA11C98DC39B44852778785B93EEFE1D00825632B56EBBBB111FBA6D6FD",
                 "productMask": []
               },
               "cardId" : "CB42000000005343",
               "cardPublicKey" : "045D5DACE8241F0015982BF1FCDF0250694FFF0FBF184899378B833D698FA3FD6F289F3B423910CF83A43A391F44BFE5E824C96736049602C3B37E3175BA17C03C",
               "defaultCurve" : "secp256k1",
               "firmwareVersion" : {
                 "hotFix" : 0,
                 "major" : 4,
                 "minor" : 12,
                 "type" : "d SDK",
                 "version" : "4.12d SDK"
               },
               "health" : 0,
               "isActivated" : false,
               "isPin1Default" : true,
               "isPin2Default" : true,
               "issuerPublicKey" : "045F16BD1D2EAFE463E62A335A09E6B2BBCBD04452526885CB679FC4D27AF1BD22F553C7DEEFB54FD3D4F361D14E6DC3F11B7D4EA183250A60720EBDF9E110CD26",
               "manufacturerName" : "TANGEM",
               "pauseBeforePin2" : 500,
               "pin2IsDefault" : true,
               "settingsMask" : [
                 "IsReusable",
                 "AllowSetPIN1",
                 "AllowSetPIN2",
                 "UseNDEF",
                 "AllowUnencrypted",
                 "AllowFastEncryption",
                 "ProtectIssuerDataAgainstReplay",
                 "AllowSelectBlockchain",
                 "DisablePrecomputedNDEF",
                 "SkipSecurityDelayIfValidatedByLinkedTerminal",
                 "RestrictOverwriteIssuerExtraData"
               ],
               "signingMethods" : [
                 "SignHash"
               ],
               "status" : "Empty",
               "terminalIsLinked" : false,
               "walletIndex" : 0,
               "wallets" : [
                 {
                   "curve" : "secp256k1",
                   "index" : 0,
                   "publicKey" : "0491906E700CA6877EB7F43FE60A981A77C321A4735078A90442C334E8790F490F5FCE6651B4B20D562C46568C0CA8BC00D5DB8F2269CB2DAD4FD31C07F1C5DBA3",
                   "settingsMask" : [
                     "IsReusable",
                     "AllowSetPIN1",
                     "AllowSetPIN2",
                     "UseNDEF",
                     "AllowUnencrypted",
                     "AllowFastEncryption",
                     "ProtectIssuerDataAgainstReplay",
                     "AllowSelectBlockchain",
                     "DisablePrecomputedNDEF",
                     "SkipSecurityDelayIfValidatedByLinkedTerminal",
                     "RestrictOverwriteIssuerExtraData"
                   ],
                   "signedHashes" : 0,
                   "status" : "Loaded"
                 },
                 {
                   "index" : 1,
                   "status" : "Empty"
                 },
                 {
                   "index" : 2,
                   "status" : "Empty"
                 },
                 {
                   "index" : 3,
                   "status" : "Empty"
                 },
                 {
                   "index" : 4,
                   "status" : "Empty"
                 }
               ],
               "walletsCount" : 5
             }
    """
}
