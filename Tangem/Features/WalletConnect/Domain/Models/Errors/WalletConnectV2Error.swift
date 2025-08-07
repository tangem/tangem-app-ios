//
//  WalletConnectV2Error.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import BlockchainSdk
import TangemLocalization
import ReownWalletKit

enum WalletConnectV2Error: LocalizedError {
    case unsupportedBlockchains([String])
    case sessionForTopicNotFound
    case missingBlockchains([String])
    case missingOptionalBlockchains([String])
    case unsupportedWCMethod(String)
    case dataInWrongFormat(String)
    case notEnoughDataInRequest(String)
    case walletModelNotFound(String)
    case missingGasLoader
    case missingEthTransactionSigner
    case missingTransaction
    case wrongCardSelected
    case sessionConnectionTimeout
    case unsupportedDApp
    case missingActiveUserWalletModel
    case userWalletRepositoryIsLocked
    case userWalletIsLocked
    case pairClientError(String)
    case symmetricKeyForTopicNotFound
    case socketConnectionTimeout
    case unsupportedWCVersion
    case unsupportedNetwork

    case unknown(String)

    var code: Int {
        switch self {
        case .unsupportedBlockchains: return 8001
        case .sessionForTopicNotFound: return 8002
        case .missingBlockchains: return 8003
        case .unsupportedWCMethod: return 8004
        case .dataInWrongFormat: return 8005
        case .notEnoughDataInRequest: return 8006
        case .walletModelNotFound: return 8007
        case .missingGasLoader: return 8009
        case .missingEthTransactionSigner: return 8010
        case .missingTransaction: return 8011
        case .wrongCardSelected: return 8013
        case .sessionConnectionTimeout: return 8014
        case .unsupportedDApp: return 8015
        case .missingActiveUserWalletModel: return 8016
        case .userWalletRepositoryIsLocked: return 8017
        case .userWalletIsLocked: return 8018
        case .pairClientError: return 8019
        case .symmetricKeyForTopicNotFound: return 8020
        case .socketConnectionTimeout: return 8022
        case .unsupportedWCVersion: return 8023
        case .missingOptionalBlockchains: return 8024
        case .unsupportedNetwork: return 8025
        case .unknown: return 8999
        }
    }

    var errorDescription: String? {
        switch self {
        case .unsupportedBlockchains(let blockchainNames):
            var message = Localization.walletConnectErrorUnsupportedBlockchains
            message += blockchainNames.joined(separator: ", ")

            return message
        case .missingBlockchains(let blockchainNames):
            var message = Localization.walletConnectErrorMissingBlockchains
            message += blockchainNames.joined(separator: ", ")

            return message
        case .missingOptionalBlockchains(let blockchainNames):
            return Localization.walletConnectErrorMissingOptionalBlockchains(
                blockchainNames.joined(separator: ", ")
            )
        case .wrongCardSelected:
            return Localization.walletConnectErrorWrongCardSelected
        case .unknown(let errorMessage):
            return Localization.walletConnectErrorWithFrameworkMessage(errorMessage)
        case .sessionConnectionTimeout:
            return Localization.walletConnectErrorTimeout
        case .unsupportedDApp:
            return Localization.walletConnectErrorUnsupportedDapp
        case .pairClientError(let errorMessage):
            return Localization.walletConnectPairingError(errorMessage)
        case .unsupportedWCVersion:
            return Localization.unsupportedWcVersion
        case .unsupportedNetwork:
            return Localization.walletConnectScannerErrorUnsupportedNetwork
        default:
            return Localization.walletConnectGenericErrorWithCode(code)
        }
    }

    init?(from string: String) {
        switch string {
        case "sessionForTopicNotFound": self = .sessionForTopicNotFound
        default:
            if string.contains("Symmetric key for topic"), string.contains("not found") {
                self = .symmetricKeyForTopicNotFound
                return
            }

            return nil
        }
    }
}

struct WalletConnectV2ErrorMappingUtils {
    func mapWCv2Error(_ error: Error) -> WalletConnectV2Error {
        let string = "\(error)"
        guard let mappedError = WalletConnectV2Error(from: string) else {
            return .unknown(string)
        }

        return mappedError
    }
}
