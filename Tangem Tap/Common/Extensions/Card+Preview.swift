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
    
    static var testEthCard: Card = {
        return fromJson(ethCardJson)
    }()
    
    static var v4Card: Card = {
        fromJson(v4CardJson)
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
    
    private static let ethCardJson =
        """
        {
          "cardData" : {
            "batchId" : "0051",
            "blockchainName" : "ETH",
            "issuerName" : "TANGEM",
            "manufactureDateTime" : "Mar 12, 2020",
            "manufacturerSignature" : "3924AC59313247C88D8AEB821CD3067CFEE82BA7C4A6F1C519C627A5FB04CD56598891F2C666BD69172E866E1511E08B2003CED0639E4C9FE390F858E4B3F001",
            "productMask" : [
              "Note"
            ]
          },
          "cardId" : "CB42000000003975",
          "cardPublicKey" : "048AB0FAEC9DA319377F6A6BAC679DE1A99239987BD1824471ADE394C970B4BCB6E2645403F1A5C1BB6814CBBA9CF3755BE1D43A4D90767119B9192A3E49CBA67D",
          "curve" : "secp256k1",
          "firmwareVersion" : {
            "hotFix" : 0,
            "major" : 3,
            "minor" : 5,
            "type" : "r",
            "version" : "3.05r"
          },
          "health" : 0,
          "isActivated" : false,
          "isPin1Default" : true,
          "isPin2Default" : true,
          "issuerPublicKey" : "048196AA4B410AC44A3B9CCE18E7BE226AEA070ACC83A9CF67540FAC49AF25129F6A538A28AD6341358E3C4F9963064F7E365372A651D374E5C23CDD37FD099BF2",
          "manufacturerName" : "TANGEM",
          "maxSignatures" : 1000000,
          "pauseBeforePin2" : 1500,
          "settingsMask" : [
            "IsReusable",
            "AllowSetPIN2",
            "UseNDEF",
            "UseDynamicNDEF",
            "SmartSecurityDelay",
            "AllowUnencrypted",
            "AllowFastEncryption",
            "ProtectIssuerDataAgainstReplay",
            "SkipSecurityDelayIfValidatedByLinkedTerminal"
          ],
          "signingMethods" : [
            "SignHash"
          ],
          "status" : "Loaded",
          "terminalIsLinked" : false,
          "walletPublicKey" : "04ECDE9F7584D27E5914652487E2668A8D26C63D550CEBC67B61C0B9A5CF80CB5B63FD7F2DC3EF4A7304678E4A918838659672063A115B133126165BC88147E685",
          "walletRemainingSignatures" : 999997,
          "walletSignedHashes" : 3
        }
        """
    
    private static let v4CardJson =
        """
        {
          "cardData" : {
            "batchId" : "FFFF",
            "issuerName" : "TANGEM SDK",
            "manufactureDateTime" : "Jan 9, 2021",
            "manufacturerSignature" : "B906FA3D536BEFA41D7425D2FC3E96B6231FC6B50D6B50318A2E95DD39C621E11E9E3EA11C98DC39B44852778785B93EEFE1D00825632B56EBBBB111FBA6D6FD",
                "productMask" : [
                  "Note"
                ]
          },
          "cardId" : "CB42000000005343",
          "cardPublicKey" : "04049C2B2B2AA75ACE9BD4BEB31D1BD2909A0FDD172801E01F7EFBD2310C9D5B2E6F816CB00C1FD92851292408596B5331B4A150FFEF199CA752EC9268892738BF",
          "defaultCurve" : "secp256k1",
          "firmwareVersion" : {
            "hotFix" : 0,
            "major" : 4,
            "minor" : 11,
            "type" : "d SDK",
            "version" : "4.11d SDK"
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
              "publicKey" : "043A966B51DE740C705C55B193682FD11BC17153F85AC8D318492CD8F4E1526E905A8B9FCFFEDD410DC5C81E60B89687741F3AC797F52FDBB33A98A9D487730714",
              "settingsMask" : [
                "IsReusable",
                "ProhibitPurgeWallet",
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
              "curve" : "ed25519",
              "index" : 1,
              "publicKey" : "070A0932A8A094E4CBC3D8813F8C6D7EEC7D9D2E3579C7D1F0641B8B62AB0C28",
              "settingsMask" : [
                "IsReusable",
                "ProhibitPurgeWallet",
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
              "curve" : "secp256r1",
              "index" : 2,
              "publicKey" : "045E328E3A8E56A8652C5B80574A53FA88EB7B63D5C519D63D84B1A67C5407195BFC5801A39C45F5F6CCB0D1607BD74212BD990FFA416F3184DD31AD2E0C2F5F94",
              "settingsMask" : [
                "IsReusable",
                "ProhibitPurgeWallet",
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
