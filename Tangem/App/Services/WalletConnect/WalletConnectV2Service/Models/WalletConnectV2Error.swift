//
//  WalletConnectV2Error.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import BlockchainSdk

enum WalletConnectV2Error: LocalizedError {
    case unsupportedBlockchains([String])
    case sessionForTopicNotFound
    case missingBlockchains([String])
    case unsupportedWCMethod(String)
    case dataInWrongFormat(String)
    case notEnoughDataInRequest(String)
    case walletModelNotFound(String)
    case missingWalletModelProviderInHandlersFactory
    case missingGasLoader
    case missingEthTransactionSigner
    case missingTransaction
    case transactionSentButNotFoundInManager
    case wrongCardSelected
    case sessionConnetionTimeout
    case unsupportedDApp
    case missingActiveUserWalletModel
    case userWalletRepositoryIsLocked
    case userWalletIsLocked
    case pairClientError(String)
    case symmetricKeyForTopicNotFound

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
        case .missingWalletModelProviderInHandlersFactory: return 8008
        case .missingGasLoader: return 8009
        case .missingEthTransactionSigner: return 8010
        case .missingTransaction: return 8011
        case .transactionSentButNotFoundInManager: return 8012
        case .wrongCardSelected: return 8013
        case .sessionConnetionTimeout: return 8014
        case .unsupportedDApp: return 8015
        case .missingActiveUserWalletModel: return 8016
        case .userWalletRepositoryIsLocked: return 8017
        case .userWalletIsLocked: return 8018
        case .pairClientError: return 8019
        case .symmetricKeyForTopicNotFound: return 8020

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
        case .wrongCardSelected:
            return Localization.walletConnectErrorWrongCardSelected
        case .unknown(let errorMessage):
            return Localization.walletConnectErrorWithFrameworkMessage(errorMessage)
        case .sessionConnetionTimeout:
            return Localization.walletConnectErrorTimeout
        case .unsupportedDApp:
            return Localization.walletConnectErrorUnsupportedDapp
        case .pairClientError(let errorMessage):
            return Localization.walletConnectPairingError(errorMessage)
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
