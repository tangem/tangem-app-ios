//
//  Card+Preview.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

extension Card {
    static var card: Card = fromJson(cardJson)

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
            if case DecodingError.keyNotFound(_, let context) = error {
                fatalError(context.debugDescription)
            }
            fatalError(error.errorDescription ?? error.localizedDescription)
        }
    }

    private static let cardJson =
        """
        {
            "backupStatus" : {
                "status" : "noBackup"
            },
            "isAccessCodeSet" : false,
            "linkedTerminalStatus" : "none",
            "cardPublicKey" : "026D5FACEA9BAB187A770AB31A9D7F330A7BFA25898A853E537200755A6770FB7D",
            "settings" : {
                "maxWalletsCount" : 20,
                "isRemovingUserCodesAllowed" : true,
                "isLinkedTerminalEnabled" : true,
                "isFilesAllowed" : true,
                "supportedEncryptionModes" : [
                    "strong",
                    "fast",
                    "none"
                ],
                "securityDelay" : 15000,
                "isBackupAllowed" : true,
                "isSettingAccessCodeAllowed" : false,
                "isHDWalletAllowed" : true,
                "isKeysImportAllowed" : false,
                "isSettingPasscodeAllowed" : false
            },
            "supportedCurves" : [
                "secp256k1",
                "ed25519",
                "secp256r1",
                "bls12381_G2",
                "bls12381_G2_AUG",
                "bls12381_G2_POP",
                "bip0340"
            ],
            "issuer" : {
                "name" : "TANGEM AG",
                "publicKey" : "0356E7C3376329DFAE7388DF1695670386103C92486A87644FA9E512C9CF4E92FE"
            },
            "firmwareVersion" : {
                "minor" : 52,
                "patch" : 0,
                "major" : 4,
                "stringValue" : "4.52r",
                "type" : "r"
            },
            "batchId" : "AC07",
            "isPasscodeSet" : false,
            "manufacturer" : {
                "name" : "TANGEM",
                "manufactureDate" : "2022-06-02",
                "signature" : "7FA19C0FEDBF642092B677DA50206C97E5496B109DF5A204D512D87652527DBF511111A1C99980C38C9D45B4EE2522DA4AEFC741CAF477CD3A43EA097D59A000"
            },
            "attestation" : {
                "cardKeyAttestation" : "verified",
                "walletKeysAttestation" : "skipped",
                "firmwareAttestation" : "skipped",
                "cardUniquenessAttestation" : "skipped"
            },
            "cardId" : "AC07000000035437",
            "wallets" : [
                {
                    "totalSignedHashes" : 76,
                    "isImported" : false,
                    "index" : 0,
                    "hasBackup" : false,
                    "derivedKeys" : { },
                    "curve" : "secp256k1",
                    "publicKey" : "03A50DB351AD9F53F45EC7C579CD4E4ABB47AF5FA50B2D4B59D1E09D99032618B7",
                    "chainCode" : "D9CC34ED5768C8D3141E2832AEE4ABEA43B5E0E9927C6D2700B6611F4A770014",
                    "settings" : {
                        "isPermanent" : false
                    }
                },
                {
                    "totalSignedHashes" : 8,
                    "isImported" : false,
                    "index" : 1,
                    "hasBackup" : false,
                    "derivedKeys" : { },
                    "curve" : "ed25519",
                    "publicKey" : "4A2DC3075B8716D3A9B7F64C6CE8FAD48AD26445E0EAEBD2A5D98B026CFBE921",
                    "chainCode" : "73068F1FC995705019AE36F2CA841BBD710EBDBAD02385CD447750A4C14335F9",
                    "settings" : {
                        "isPermanent" : false
                    }
                }
            ],
            "userSettings" : {
                "isUserCodeRecoveryAllowed" : true
            }
        }
        """
}
