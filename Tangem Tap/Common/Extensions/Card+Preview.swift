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
    
    
    static var testCardNoWallet: Card = {
        fromJson(noWalletJson)
    }()
    
    static var testTwinCard: Card = {
        fromJson(twinCardJson)
    }()
    
    static var testEthCard: Card = {
        fromJson(ethCardJson)
    }()
    
    static var testXlmCard: Card = {
        fromJson(stellarCardJson)
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
    
    private static let noWalletJson =
        """
          {
            "cardData" : {
              "batchId" : "FFFF",
              "blockchainName" : "BTC",
              "issuerName" : "TANGEM SDK",
              "manufactureDateTime" : "Jan 12, 2021",
              "manufacturerSignature" : "5351B94FCD7362B6F8CFAA0499DDD9804FAF81DB7F1C98AE115DC268496B15583463C643AE9C3F49D3B6FB8215EAF6EBF5A6C5D99DA914F2228DB281FB80EB29",
              "productMask" : [
                "Note"
              ]
            },
            "cardId" : "BB03000000000004",
            "cardPublicKey" : "04EF1B1B775D3DE6CBB6DD52DE7F3A30AC45F681597002F4B19B65BF6AA306A8DA6CD5295C247D6E9769E0083DF5F8D04AC892DB09EC8F38093E3073C34A59A553",
            "defaultCurve" : "secp256k1",
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
            "status" : "Empty",
            "terminalIsLinked" : false,
            "wallets" : [
              {
                "curve" : "secp256k1",
                "index" : 0,
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
                "status" : "Empty"
              }
            ]
          }
        """
    
    private static let twinCardJson =
        """
         {
          "cardData" : {
            "batchId" : "FFFF",
            "blockchainName" : "BTC",
            "issuerName" : "TANGEM SDK",
            "manufactureDateTime" : "Dec 18, 2020",
            "manufacturerSignature" : "B55FAB99AF49A6AE31A8E23C67C53338ADFB0EEF805247381845F65E7020F541544700942B1B3EFD16EF125B4A2EC718CD24979879E49E60F3CB173072F828AC",
            "productMask" : [
              "TwinCard"
            ]
          },
          "cardId" : "CB62000000005629",
          "cardPublicKey" : "04007CB1D0C643C86E30579576A10068A5B03DC6363968712DEA5D298A47E5F723696AE5C211D331BF9A4A0DBF94C539FE51B62D6FA8572399B924529B307DD589",
          "defaultCurve" : "secp256k1",
          "firmwareVersion" : {
            "hotFix" : 0,
            "major" : 3,
            "minor" : 29,
            "type" : "d SDK",
            "version" : "3.29d SDK"
          },
          "health" : 0,
          "isActivated" : false,
          "isPin1Default" : true,
          "isPin2Default" : true,
          "issuerPublicKey" : "048196AA4B410AC44A3B9CCE18E7BE226AEA070ACC83A9CF67540FAC49AF25129F6A538A28AD6341358E3C4F9963064F7E365372A651D374E5C23CDD37FD099BF2",
          "manufacturerName" : "TANGEM",
          "pauseBeforePin2" : 1500,
          "settingsMask" : [
            "IsReusable",
            "AllowSetPIN1",
            "AllowSetPIN2",
            "UseNDEF",
            "AllowUnencrypted",
            "AllowFastEncryption",
            "ProtectIssuerDataAgainstReplay",
            "DisablePrecomputedNDEF",
            "SkipSecurityDelayIfValidatedByLinkedTerminal",
            "RestrictOverwriteIssuerExtraData"
          ],
          "signingMethods" : [
            "SignHash"
          ],
          "status" : "Loaded",
          "terminalIsLinked" : false,
          "wallets" : [
            {
              "curve" : "secp256k1",
              "index" : 0,
              "publicKey" : "040F5088849BA1C1FCA4E65EF7137D4246C9F399DBC5408415FD3829C78DA13126B095AFEDE9E66EDFF3C914E282F02D04CED8D36CDA07CA3DE04B14E448E7609A",
              "remainingSignatures" : 999998,
              "settingsMask" : [
                "IsReusable",
                "AllowSetPIN1",
                "AllowSetPIN2",
                "UseNDEF",
                "AllowUnencrypted",
                "AllowFastEncryption",
                "ProtectIssuerDataAgainstReplay",
                "DisablePrecomputedNDEF",
                "SkipSecurityDelayIfValidatedByLinkedTerminal",
                "RestrictOverwriteIssuerExtraData"
              ],
              "signedHashes" : 1,
              "status" : "Loaded"
            }
          ]
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
          "defaultCurve" : "secp256k1",
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
          "wallets" : [
            {
              "curve" : "secp256k1",
              "index" : 0,
              "publicKey" : "04ECDE9F7584D27E5914652487E2668A8D26C63D550CEBC67B61C0B9A5CF80CB5B63FD7F2DC3EF4A7304678E4A918838659672063A115B133126165BC88147E685",
              "remainingSignatures" : 999968,
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
              "signedHashes" : 32,
              "status" : "Loaded"
            }
          ]
        }
        """
    
    private static let stellarCardJson =
    """
        {
          "cardData" : {
            "batchId" : "0052",
            "blockchainName" : "XLM",
            "issuerName" : "TANGEM",
            "manufactureDateTime" : "Mar 12, 2020",
            "manufacturerSignature" : "5D001070E4C660CDC19F4B779147F866B7476FD1EB86DD13BF13D1E602B6869A56A24E6B1FED9F629537CE10112D139B107A2FFF2DF25F7E3CA87F4938E74A58",
            "productMask" : [
              "Note"
            ]
          },
          "cardId" : "CB43000000002950",
          "cardPublicKey" : "04F1CDEE71100B81322CA82A61E760A235325A721059F92DC613F41B5E9C9571B06E34FF39EF8775825B168B19C0259EA141E89DB3A335162DCB1CDE0E994143C6",
          "defaultCurve" : "ed25519",
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
          "wallets" : [
            {
              "curve" : "ed25519",
              "index" : 0,
              "publicKey" : "9FE5BB2CC7D83C1DA10845AFD8A34B141FD8FD72500B95B1547E12B9BB8AAC3D",
              "remainingSignatures" : 999992,
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
              "signedHashes" : 8,
              "status" : "Loaded"
            }
          ]
        }
    """
    
    private static let v4CardJson =
        """
        {
          "cardData" : {
            "batchId" : "CB79",
            "issuerName" : "TANGEM SDK",
            "manufactureDateTime" : "Jan 9, 2021",
            "manufacturerSignature" : "B906FA3D536BEFA41D7425D2FC3E96B6231FC6B50D6B50318A2E95DD39C621E11E9E3EA11C98DC39B44852778785B93EEFE1D00825632B56EBBBB111FBA6D6FD",
                "productMask" : [
                  "Note"
                ]
          },
          "cardId" : "CB79000000005343",
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
