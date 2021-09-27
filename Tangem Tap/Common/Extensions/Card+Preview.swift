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
    
    static var v4Card: Card = {
        fromJson(v4CardJson)
    }()
    
    static var cardanoNote: Card = {
        fromJson(cardanoNoteJson)
    }()
    
    static var cardanoNoteEmptyWallet: Card = {
        fromJson(cardanoNoteEmptyWalletJson)
    }()
    
    static var ethEmptyNote: Card = {
        fromJson(ethEmptyNoteJson)
    }()
    
    static var emptyTangemWallet: Card = {
        fromJson(emptyTangemWalletJson)
    }()
    
    private static func fromJson(_ json: String) -> Card {
        let jsonData = json.data(using: .utf8)!
        let decoder = JSONDecoder.tangemSdkDecoder
        decoder.keyDecodingStrategy = .useDefaultKeys
        do {
            let card = try decoder.decode(Card.self, from: jsonData)
            return card
        } catch {
            guard let error = error as? DecodingError else {
                fatalError(error.localizedDescription)
            }
            if case let DecodingError.keyNotFound(_, context) = error {
                fatalError(context.debugDescription)
                
                /// If preview throw you this error check your card JSON. May be there missing fields in Card.Settings
                /// You can try add folowing fields to fix preview carsh
                /// "isOverwritingIssuerExtraDataRestricted" : false,
                /// "isIssuerDataProtectedAgainstReplay" : true,
                /// "isSelectBlockchainAllowed" : true
            }
            fatalError(error.errorDescription ?? error.localizedDescription)
        }
    }
    
    private static let noWalletJson =
        """
                {
                  "linkedTerminalStatus" : "none",
                  "supportedCurves" : [
                    "secp256k1",
                    "ed25519",
                    "secp256r1"
                  ],
                  "cardPublicKey" : "0400D05BCAC34B58AA48BF998FB68667A3112262275200431EA235EC4616A15287B5D21F15E45740AB6B829F415950DBC7A68493DCF5FD270C8CAAB0E975E9A0D9",
                  "settings" : {
                    "isSettingPasscodeAllowed" : true,
                    "maxWalletsCount" : 36,
                    "isOverwritingIssuerExtraDataRestricted" : false,
                    "isResettingUserCodesAllowed" : false,
                    "isLinkedTerminalEnabled" : true,
                    "securityDelay" : 3000,
                    "isHDWalletsAllowed" : false,
                    "isBackupAllowed" : false,
                    "isSettingAccessCodeAllowed" : false,
                    "supportedEncryptionModes" : [
                      "strong",
                      "fast",
                      "none"
                    ],
                    "isPermanentWallet" : true,
                    "isSelectBlockchainAllowed" : true,
                    "isIssuerDataProtectedAgainstReplay" : true
                  },
                  "issuer" : {
                    "name" : "TANGEM AG",
                    "publicKey" : "0456E7C3376329DFAE7388DF1695670386103C92486A87644FA9E512C9CF4E92FE970EFDFBB7A35446F2A937505E6C70D78E965533B31C252B607F3C6B3112B603"
                  },
                  "firmwareVersion" : {
                    "minor" : 12,
                    "patch" : 0,
                    "major" : 4,
                    "stringValue" : "4.12r",
                    "type" : "r"
                  },
                  "batchId" : "CB79",
                  "attestation" : {
                    "cardKeyAttestation" : "verified",
                    "walletKeysAttestation" : "verified",
                    "firmwareAttestation" : "skipped",
                    "cardUniquenessAttestation" : "skipped"
                  },
                  "manufacturer" : {
                    "name" : "TANGEM",
                    "manufactureDate" : "2021-04-01",
                    "signature" : "1671A9AB2D9D5B99177E841C8DC35842452A095088CD01B48D753631571AAB21EEAC0F96BC87142268C32EFB3AF8A8C80DB55BE6D1970FAFBC72E00F896F69EA"
                  },
                  "cardId" : "CB79000000018201",
                  "wallets" : [],
                  "isPin2Default" : true
                }
        """
    
    private static let twinCardJson =
        """
        {
          "cardId" : "CB62000000001263",
          "issuer" : {
            "name" : "TANGEM",
            "publicKey" : "048196AA4B410AC44A3B9CCE18E7BE226AEA070ACC83A9CF67540FAC49AF25129F6A538A28AD6341358E3C4F9963064F7E365372A651D374E5C23CDD37FD099BF2"
          },
          "manufacturer" : {
            "name" : "TANGEM",
            "manufactureDate" : "2020-12-01",
            "signature" : "DD6E0F1B8B1D981AD4968FB701598B4441F7F57471625BA396C4517897E0CA07DE60473284DCE5FB72875DAFB1D711781A324FFB6BC37761B087045ADAFC3A1E"
          },
          "linkedTerminalStatus" : "none",
          "supportedCurves" : [
            "secp256k1"
          ],
          "batchId" : "0074",
          "firmwareVersion" : {
            "minor" : 29,
            "patch" : 0,
            "major" : 3,
            "stringValue" : "3.29r",
            "type" : "r"
          },
          "wallets" : [
           
          ],
          "attestation" : {
            "cardKeyAttestation" : "verified",
            "walletKeysAttestation" : "skipped",
            "firmwareAttestation" : "skipped",
            "cardUniquenessAttestation" : "skipped"
          },
          "cardPublicKey" : "0432BA381ABFB824658216BEB1C92E603CBCBA3171F3C1400C397D890A670FA84FC24ED388D7F608ECA7A6FA696806E20B341C4688DB361B4E2D4BE042B77B9FE9",
          "settings" : {
            "isPermanentWallet" : false,
            "maxWalletsCount" : 1,
            "isLinkedTerminalEnabled" : true,
            "supportedEncryptionModes" : [
              "strong",
              "fast",
              "none"
            ],
            "securityDelay" : 15000,
            "isSettingAccessCodeAllowed" : true,
            "isResettingUserCodesAllowed" : false,
            "isHDWalletsAllowed" : false,
            "isBackupAllowed" : false,
            "isSettingPasscodeAllowed" : true,
            "isOverwritingIssuerExtraDataRestricted" : false,
            "isIssuerDataProtectedAgainstReplay" : true,
            "isSelectBlockchainAllowed" : true,
          }
        }


        """
    
    private static let v4CardJson =
        """
        {
          "linkedTerminalStatus" : "none",
          "supportedCurves" : [
            "secp256k1",
            "ed25519",
            "secp256r1"
          ],
          "cardPublicKey" : "0400D05BCAC34B58AA48BF998FB68667A3112262275200431EA235EC4616A15287B5D21F15E45740AB6B829F415950DBC7A68493DCF5FD270C8CAAB0E975E9A0D9",
          "settings" : {
            "isSettingPasscodeAllowed" : true,
            "maxWalletsCount" : 36,
            "isOverwritingIssuerExtraDataRestricted" : false,
            "isResettingUserCodesAllowed" : false,
            "isLinkedTerminalEnabled" : true,
            "isHDWalletsAllowed" : false,
            "isBackupAllowed" : false,
            "securityDelay" : 3000,
            "isSettingAccessCodeAllowed" : false,
            "supportedEncryptionModes" : [
              "strong",
              "fast",
              "none"
            ],
            "isPermanentWallet" : true,
            "isSelectBlockchainAllowed" : true,
            "isIssuerDataProtectedAgainstReplay" : true
          },
          "issuer" : {
            "name" : "TANGEM AG",
            "publicKey" : "0456E7C3376329DFAE7388DF1695670386103C92486A87644FA9E512C9CF4E92FE970EFDFBB7A35446F2A937505E6C70D78E965533B31C252B607F3C6B3112B603"
          },
          "firmwareVersion" : {
            "minor" : 12,
            "patch" : 0,
            "major" : 4,
            "stringValue" : "4.12r",
            "type" : "r"
          },
          "batchId" : "CB79",
          "attestation" : {
            "cardKeyAttestation" : "verified",
            "walletKeysAttestation" : "verified",
            "firmwareAttestation" : "skipped",
            "cardUniquenessAttestation" : "skipped"
          },
          "manufacturer" : {
            "name" : "TANGEM",
            "manufactureDate" : "2021-04-01",
            "signature" : "1671A9AB2D9D5B99177E841C8DC35842452A095088CD01B48D753631571AAB21EEAC0F96BC87142268C32EFB3AF8A8C80DB55BE6D1970FAFBC72E00F896F69EA"
          },
          "cardId" : "CB79000000018201",
          "wallets" : [
            {
              "publicKey" : "FA3F41EE40DAB4DB96B4AD5BEC697A552EEB1AACF2C6A10B1B37A9A724608533",
              "totalSignedHashes" : 1,
              "curve" : "ed25519",
              "settings" : {
                "isPermanent" : false
              },
              "hasBackup": false,
              "index" : 0
            },
            {
              "publicKey" : "0440C533E007D029C1F345CA70A9F6016EC7A95C775B6320AE84248F20B647FBBD90FF56A2D9C3A1984279ED2367274A49079789E130444541C2F15907D5570B49",
              "totalSignedHashes" : 0,
              "curve" : "secp256k1",
              "settings" : {
                "isPermanent" : true
              },
              "index" : 1
            },
            {
              "publicKey" : "04DDFACEF55A95EAB2CDCC8E86CE779342D2E2A53CF8F0F20BF2B248336AE3EEA6DD62D1F4C5420A71D6212073B136034CDC878DAD3AE3FDFA3360E6FE6184F470",
              "totalSignedHashes" : 0,
              "curve" : "secp256r1",
              "settings" : {
                "isPermanent" : true
              },
              "index" : 2
            }
          ],
          "isPin2Default" : true
        }
        """
    
    private static let cardanoNoteJson =
    """
        {
          "linkedTerminalStatus" : "none",
          "supportedCurves" : [
            "secp256k1",
            "ed25519",
            "secp256r1"
          ],
          "cardPublicKey" : "04D328D24A10A142DE0FAF8F49CCDE93BD173C391ADC7319EA833659B4F6D0716ED3CD5A096A1AE10B5CA6ACFC0A9DCCF789427709BE35024E6795C50DA53353A1",
          "settings" : {
            "isPermanentWallet" : false,
            "maxWalletsCount" : 3,
            "isLinkedTerminalEnabled" : true,
            "supportedEncryptionModes" : [
              "strong",
              "fast",
              "none"
            ],
            "securityDelay" : 5000,
            "isSettingAccessCodeAllowed" : true,
            "isResettingUserCodesAllowed" : false,
            "isSettingPasscodeAllowed" : true,
            "isHDWalletsAllowed" : false,
            "isBackupAllowed" : false,
            "isOverwritingIssuerExtraDataRestricted" : false,
            "isIssuerDataProtectedAgainstReplay" : true,
            "isSelectBlockchainAllowed" : true
          },
          "issuer" : {
            "name" : "TANGEM SDK",
            "publicKey" : "045F16BD1D2EAFE463E62A335A09E6B2BBCBD04452526885CB679FC4D27AF1BD22F553C7DEEFB54FD3D4F361D14E6DC3F11B7D4EA183250A60720EBDF9E110CD26"
          },
          "firmwareVersion" : {
            "minor" : 12,
            "patch" : 0,
            "major" : 4,
            "stringValue" : "4.12d SDK",
            "type" : "d SDK"
          },
          "batchId" : "AB03",
          "isPasscodeSet" : false,
          "manufacturer" : {
            "name" : "TANGEM",
            "manufactureDate" : "2021-07-28",
            "signature" : "CE27C98C0FE9C57DC205BE9B4077C4CF6CBE5248E0BB03C00D6FD9C868CB7F96DFF228B74FFE88783524119B4B3E31494BB592DCB59207AA6DB7635F45D691C9"
          },
          "attestation" : {
            "cardKeyAttestation" : "failed",
            "walletKeysAttestation" : "skipped",
            "firmwareAttestation" : "skipped",
            "cardUniquenessAttestation" : "skipped"
          },
          "cardId" : "AB03000000046298",
          "wallets" : [
            {
              "publicKey" : "04FCD0CE2067A0573F6E9E5F985ABF234E07BBA7EC1D09381F53C9399E536DBE38D90402DB3D05B6A9EFDEB1B82A6C90E6706509FAAC614830C273D5FDC4F8931E",
              "totalSignedHashes" : 0,
              "curve" : "secp256k1",
              "settings" : {
                "isPermanent" : false
              },
              "hasBackup": false,
              "index" : 0
            },
            {
              "publicKey" : "04DE4B97A6F23F53CA1E01D5317DEE3B597346F7FBB220117894D76222A4B5CC6CAAD30AB22B0DBF2D595F18BF82B73AA4792C2471D0F1BBF95A57167B6830871C",
              "totalSignedHashes" : 0,
              "curve" : "secp256r1",
              "settings" : {
                "isPermanent" : false
              },
              "hasBackup": false,
              "index" : 1
            },
            {
              "publicKey" : "AD601190A88E271798D3B54DA853DEE3AC35C6F66E6A2E7E4F758CDA958FE365",
              "totalSignedHashes" : 0,
              "curve" : "ed25519",
              "settings" : {
                "isPermanent" : false
              },
              "hasBackup": false,
              "index" : 2
            }
          ]
        }
    """
    
    private static let cardanoNoteEmptyWalletJson =
    """
        {
          "linkedTerminalStatus" : "none",
          "supportedCurves" : [
            "secp256k1",
            "ed25519",
            "secp256r1"
          ],
          "cardPublicKey" : "04D328D24A10A142DE0FAF8F49CCDE93BD173C391ADC7319EA833659B4F6D0716ED3CD5A096A1AE10B5CA6ACFC0A9DCCF789427709BE35024E6795C50DA53353A1",
          "settings" : {
            "isPermanentWallet" : false,
            "maxWalletsCount" : 3,
            "isLinkedTerminalEnabled" : true,
            "supportedEncryptionModes" : [
              "strong",
              "fast",
              "none"
            ],
            "securityDelay" : 5000,
            "isSettingAccessCodeAllowed" : true,
            "isResettingUserCodesAllowed" : false,
            "isSettingPasscodeAllowed" : true,            
            "isHDWalletsAllowed" : false,
            "isBackupAllowed" : false,
            "isOverwritingIssuerExtraDataRestricted" : false,
            "isIssuerDataProtectedAgainstReplay" : true,
            "isSelectBlockchainAllowed" : true
          },
          "issuer" : {
            "name" : "TANGEM SDK",
            "publicKey" : "045F16BD1D2EAFE463E62A335A09E6B2BBCBD04452526885CB679FC4D27AF1BD22F553C7DEEFB54FD3D4F361D14E6DC3F11B7D4EA183250A60720EBDF9E110CD26"
          },
          "firmwareVersion" : {
            "minor" : 12,
            "patch" : 0,
            "major" : 4,
            "stringValue" : "4.12d SDK",
            "type" : "d SDK"
          },
          "batchId" : "AB03",
          "isPasscodeSet" : false,
          "manufacturer" : {
            "name" : "TANGEM",
            "manufactureDate" : "2021-07-28",
            "signature" : "CE27C98C0FE9C57DC205BE9B4077C4CF6CBE5248E0BB03C00D6FD9C868CB7F96DFF228B74FFE88783524119B4B3E31494BB592DCB59207AA6DB7635F45D691C9"
          },
          "attestation" : {
            "cardKeyAttestation" : "failed",
            "walletKeysAttestation" : "skipped",
            "firmwareAttestation" : "skipped",
            "cardUniquenessAttestation" : "skipped"
          },
          "cardId" : "AB03000000046298",
          "wallets" : [
            {
              "publicKey" : "04FCD0CE2067A0573F6E9E5F985ABF234E07BBA7EC1D09381F53C9399E536DBE38D90402DB3D05B6A9EFDEB1B82A6C90E6706509FAAC614830C273D5FDC4F8931E",
              "totalSignedHashes" : 0,
              "curve" : "secp256k1",
              "settings" : {
                "isPermanent" : false
              },
              "hasBackup": false,
              "index" : 0
            },
            {
              "publicKey" : "04DE4B97A6F23F53CA1E01D5317DEE3B597346F7FBB220117894D76222A4B5CC6CAAD30AB22B0DBF2D595F18BF82B73AA4792C2471D0F1BBF95A57167B6830871C",
              "totalSignedHashes" : 0,
              "curve" : "secp256r1",
              "settings" : {
                "isPermanent" : false
              },
              "hasBackup": false,
              "index" : 1
            },
            {
              "publicKey" : "AD701190A88E271798D3B54DA853DEE3AC35C6F66E6A2E7E4F758CDA958FE365",
              "totalSignedHashes" : 0,
              "curve" : "ed25519",
              "settings" : {
                "isPermanent" : false
              },
              "hasBackup": false,
              "index" : 2
            }
          ]
        }
    """
    
    private static let ethEmptyNoteJson =
    """
    {
      "linkedTerminalStatus" : "none",
      "supportedCurves" : [
        "secp256k1",
        "ed25519",
        "secp256r1"
      ],
      "cardPublicKey" : "04E09490FAF76B27DB193268D84C0F91C8B705B2B79C7257714C39ACCFEA157B2CBCF9DD7E72E779F114BEC5BF1B47481B85A7D8F3698F79C453C186ECFEEEADE4",
      "settings" : {
        "isPermanentWallet" : false,
        "maxWalletsCount" : 3,
        "isLinkedTerminalEnabled" : true,
        "supportedEncryptionModes" : [
          "strong",
          "fast",
          "none"
        ],
        "securityDelay" : 5000,
        "isSettingAccessCodeAllowed" : true,
        "isResettingUserCodesAllowed" : false,
        "isSettingPasscodeAllowed" : true,
            "isHDWalletsAllowed" : false,
            "isBackupAllowed" : false,
        "isOverwritingIssuerExtraDataRestricted" : false,
        "isIssuerDataProtectedAgainstReplay" : true,
        "isSelectBlockchainAllowed" : true
      },
      "issuer" : {
        "name" : "TANGEM SDK",
        "publicKey" : "045F16BD1D2EAFE463E62A335A09E6B2BBCBD04452526885CB679FC4D27AF1BD22F553C7DEEFB54FD3D4F361D14E6DC3F11B7D4EA183250A60720EBDF9E110CD26"
      },
      "firmwareVersion" : {
        "minor" : 12,
        "patch" : 0,
        "major" : 4,
        "stringValue" : "4.12d SDK",
        "type" : "d SDK"
      },
      "batchId" : "AB02",
      "isPasscodeSet" : false,
      "manufacturer" : {
        "name" : "TANGEM",
        "manufactureDate" : "2021-07-28",
        "signature" : "457D2D85B983ED3872A0FA8A44400236B347752D49E64F71BD375EDF77E3317EF2E352A44CB97AAF377CF44F8DB6D178819A223CF2CFCED09AE4E270EB29FD91"
      },
      "attestation" : {
        "cardKeyAttestation" : "failed",
        "walletKeysAttestation" : "skipped",
        "firmwareAttestation" : "skipped",
        "cardUniquenessAttestation" : "skipped"
      },
      "cardId" : "AB02000000016433",
      "wallets" : [
      
      ]
    }
    """
    
    private static let emptyTangemWalletJson =
    """
        {
          "linkedTerminalStatus" : "none",
          "supportedCurves" : [
            "secp256k1",
            "ed25519",
            "secp256r1"
          ],
          "cardPublicKey" : "049BE092BE8D41DBA49A0CD861DC3C4E6DF43983331701A92EDBA47319D5BCB5CE32AB5876971B0025ED9EDB4A4900C364E7E3BA7F7D5C001BD35A104442E29C42",
          "settings" : {
            "isPermanentWallet" : false,
            "maxWalletsCount" : 40,
            "isLinkedTerminalEnabled" : true,
            "supportedEncryptionModes" : [
              "strong",
              "fast",
              "none"
            ],
            "securityDelay" : 5000,
            "isSettingAccessCodeAllowed" : true,
            "isResettingUserCodesAllowed" : false,
            "isSettingPasscodeAllowed" : true,
            "isHDWalletsAllowed" : true,
            "isBackupAllowed" : true,
            "isOverwritingIssuerExtraDataRestricted" : false,
            "isIssuerDataProtectedAgainstReplay" : true,
            "isSelectBlockchainAllowed" : true
          },
          "issuer" : {
            "name" : "TANGEM SDK",
            "publicKey" : "045F16BD1D2EAFE463E62A335A09E6B2BBCBD04452526885CB679FC4D27AF1BD22F553C7DEEFB54FD3D4F361D14E6DC3F11B7D4EA183250A60720EBDF9E110CD26"
          },
          "firmwareVersion" : {
            "minor" : 12,
            "patch" : 0,
            "major" : 4,
            "stringValue" : "4.12d SDK",
            "type" : "d SDK"
          },
          "batchId" : "AC01",
          "isPasscodeSet" : false,
          "manufacturer" : {
            "name" : "TANGEM",
            "manufactureDate" : "2021-07-28",
            "signature" : "60D4C520BE3F0C3567F7DBC49AF457B94BEBED50F5779C9DDB16196D94FADFC112593AD60C6ABDE9E34C336CC44ACAE31A548EA7D7EF4607793F382B04C45511"
          },
          "attestation" : {
            "cardKeyAttestation" : "failed",
            "walletKeysAttestation" : "skipped",
            "firmwareAttestation" : "skipped",
            "cardUniquenessAttestation" : "skipped"
          },
          "cardId" : "AC01000000028396",
          "wallets" : [
    
          ]
        }
    """
}
