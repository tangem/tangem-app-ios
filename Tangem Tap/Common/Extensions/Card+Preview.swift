//
//  Card+Preview.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

extension Card {
    static var testCard: Card  = {
        return fromJson(testCardJson)
    }()
    
    static var testCardNoWallet: Card = {
        return fromJson(noWalletJson)
    }()
	
	static var testTwinCard: Card = {
		fromJson(twinCardJson)
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
                "blockchainName" : "BTC",
                "issuerName" : "TANGEM SDK",
                "manufactureDateTime" : "Mar 16, 2020",
                "manufacturerSignature" : "E4A2403C60F6C468D7ED50E3BE3AF903AF3C6A2A6ABA2F8369584C91E15F42DAF90E4F9ABFBA1E5FBB3965CA30FC2C4F57CC34C8460B6E12D5CDBEBB1838D5C7",
                "productMask" : [
                  "Note"
                ]
              },
              "cardId" : "BB00000000000239",
              "cardPublicKey" : "0405B26CACB20F3015322C450F8A47D4EEA94225155D5E5D80E2409A3F96EB1C2FE71E95EDA418EED93582C680E2BBEBA34B96D7F52381C29F2A700D3EC7E8CFBC",
              "curve" : "Secp256K1",
    "firmwareVersion" : {
    "hotFix" : 0,
    "major" : 2,
    "minor" : 42,
    "type" : "d SDK",
    "version" : "2.42d SDK"
    },
              "health" : 0,
              "isActivated" : false,
              "issuerPublicKey" : "045F16BD1D2EAFE463E62A335A09E6B2BBCBD04452526885CB679FC4D27AF1BD22F553C7DEEFB54FD3D4F361D14E6DC3F11B7D4EA183250A60720EBDF9E110CD26",
              "manufacturerName" : "TANGEM",
              "maxSignatures" : 19040,
              "pauseBeforePin2" : 500,
              "remainingSignatures" : 19034,
              "settingsMask" : [
                "IsReusable",
                "AllowSetPIN1",
                "AllowSetPIN2",
                "UseDynamicNDEF",
                "AllowUnencrypted",
                "AllowFastEncryption",
                "ProtectIssuerDataAgainstReplay",
                "SkipSecurityDelayIfValidatedByIssuer",
                "SkipCheckPIN2CVCIfValidatedByIssuer",
                "SkipSecurityDelayIfValidatedByLinkedTerminal",
                "RestrictOverwriteIssuerExtraDara",
                "CheckPIN3OnCard"
              ],
              "signedHashes" : 6,
              "signingMethod" : [
                "SignHash",
                "SignRaw"
              ],
              "status" : "Loaded",
              "terminalIsLinked" : false,
              "walletPublicKey" : "041DCEFEF8FA536EE746707E800400C61B7F87B1E06A58F1AA04B4C0E36DF445655A089C351AE670FA5778620F06624FB4014C1B07EB436B8D47186B063530B560",
              "walletRemainingSignatures" : 19034,
              "walletSignedHashes" : 6
            }
    """
    
    private static let noWalletJson =
    """
             {
              "cardData" : {
                "batchId" : "FFFF",
                "blockchainName" : "ETH",
                "issuerName" : "TANGEM SDK",
                "manufactureDateTime" : "Mar 16, 2020",
                "manufacturerSignature" : "E4A2403C60F6C468D7ED50E3BE3AF903AF3C6A2A6ABA2F8369584C91E15F42DAF90E4F9ABFBA1E5FBB3965CA30FC2C4F57CC34C8460B6E12D5CDBEBB1838D5C7",
                "productMask" : [
                  "Note"
                ]
              },
              "cardId" : "BB00000000000238",
              "cardPublicKey" : "0405B26CACB20F3015322C450F8A47D4EEA94225155D5E5D80E2409A3F96EB1C2FE71E95EDA418EED93582C680E2BBEBA34B96D7F52381C29F2A700D3EC7E8CFBC",
              "curve" : "Secp256K1",
               "firmwareVersion" : {
      "hotFix" : 0,
      "major" : 2,
      "minor" : 24,
      "type" : "d SDK",
      "version" : "2.24d SDK"
    },
              "health" : 0,
              "isActivated" : false,
              "issuerPublicKey" : "045F16BD1D2EAFE463E62A335A09E6B2BBCBD04452526885CB679FC4D27AF1BD22F553C7DEEFB54FD3D4F361D14E6DC3F11B7D4EA183250A60720EBDF9E110CD26",
              "manufacturerName" : "TANGEM",
              "maxSignatures" : 19040,
              "pauseBeforePin2" : 500,
              "remainingSignatures" : 19034,
              "settingsMask" : [
                "IsReusable",
                "AllowSetPIN1",
                "AllowSetPIN2",
                "UseDynamicNDEF",
                "AllowUnencrypted",
                "AllowFastEncryption",
                "ProtectIssuerDataAgainstReplay",
                "SkipSecurityDelayIfValidatedByIssuer",
                "SkipCheckPIN2CVCIfValidatedByIssuer",
                "SkipSecurityDelayIfValidatedByLinkedTerminal",
                "RestrictOverwriteIssuerExtraDara",
                "CheckPIN3OnCard"
              ],
              "signedHashes" : 6,
              "signingMethod" : [
                "SignHash",
                "SignRaw"
              ],
              "status" : "Loaded",
              "terminalIsLinked" : false,
              "walletRemainingSignatures" : 19034,
              "walletSignedHashes" : 6
            }
    """
	
	private static let twinCardJson =
	"""
		{
		  "cardData" : {
			"batchId" : "FFFF",
			"blockchainName" : "BTC",
			"issuerName" : "TANGEM SDK",
			"manufactureDateTime" : "Dec 2, 2020",
			"manufacturerSignature" : "BF9466B0F0C7BFC67A3E782EE193DDB53D987F5615AC797E332C964D2D485B36F87CC8045A2FA1744934419C115608DBE5BC7F79F930E0577D4F9013F09FB96A",
			"productMask" : [
			  "TwinCard"
			]
		  },
		  "cardId" : "CB64000000056786",
		  "cardPublicKey" : "046CF604F0107B1695D459C790F86E0F7659AB4FC26E0F69C4F25EC7044EFB114B92C2A8587A85D9E4B2D8FFDEA109769EB997331FFA71DC7F3EBF1F3D18F4C547",
		  "curve" : "Secp256K1",
		  "firmwareVersion" : {
			"hotFix" : 0,
			"major" : 3,
			"minor" : 37,
			"type" : "d SDK",
			"version" : "3.37d SDK"
		  },
		  "health" : 0,
		  "isActivated" : false,
		  "isPin1Default" : true,
		  "isPin2Default" : true,
		  "issuerPublicKey" : "045F16BD1D2EAFE463E62A335A09E6B2BBCBD04452526885CB679FC4D27AF1BD22F553C7DEEFB54FD3D4F361D14E6DC3F11B7D4EA183250A60720EBDF9E110CD26",
		  "manufacturerName" : "TANGEM",
		  "maxSignatures" : 999999,
		  "pauseBeforePin2" : 500,
		  "settingsMask" : [
			"IsReusable",
			"AllowSetPIN1",
			"AllowSetPIN2",
			"UseNDEF",
			"UseDynamicNDEF",
			"SmartSecurityDelay",
			"AllowUnencrypted",
			"AllowFastEncryption",
			"SkipSecurityDelayIfValidatedByIssuer",
			"SkipCheckPIN2CVCIfValidatedByIssuer",
			"SkipSecurityDelayIfValidatedByLinkedTerminal"
		  ],
		  "signingMethods" : [
			"SignHash"
		  ],
		  "status" : "Loaded",
		  "terminalIsLinked" : false,
		  "walletPublicKey" : "049CF238FB442E307241FC468613F9F1306CFA872DC6CF2D6B0DE51B6755173AEAC5EAA02D5E53A119A67F7778C6335294DE850039FF32B1E71ACA36947BEF57CD",
		  "walletRemainingSignatures" : 999993,
		  "walletSignedHashes" : 6
		}
	"""
}
