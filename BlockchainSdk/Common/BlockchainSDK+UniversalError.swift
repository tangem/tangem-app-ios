//
//  BlockchainSDK+UniversalError.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemFoundation
import SolanaSwift

// `Subsystems`:
// `000` - BlockchainSdkError
// `001` - AlephiumError
// `002` - ScriptChunkError
// `003` - CardanoError
// `004` - CasperError
// `005` - ChiaError
// `006` - ETHError
// `007` - FilecoinError
// `008` - HederaError
// `009` - KoinosError
// `010` - SolanaError & SolanaBSDKError
// `011` - SuiError
// `012` - TONError
// `013` - TronError
// `014` - VeChainError
// `015` - XRPError
// `016` - PolygonScanAPIError
// `017` - WebSocketConnectionError
// `018` - CashAddrBech32.DecodeError
// `019` - TransferERC721TokenMethod.Error
// `020` - TransferERC1155TokenMethod.Error
// `021` - KaspaKRC20.Error
// `022` - SubscanAPIResult.Error
// `023` - SS58.Error
// `024` - ValidationError
// `025` - YieldModuleError
// `026` - BTCError

extension BlockchainSdkError: UniversalError {
    public var errorCode: Int {
        switch self {
        case .accountNotActivated:
            return 102000000
        case .addressesIsEmpty:
            return 102000001
        case .blockchainUnavailable(let underlyingError):
            if let universal = underlyingError as? UniversalError {
                return universal.errorCode
            }

            return 102000002
        case .decodingFailed:
            return 102000003
        case .empty:
            return 102000004
        case .failedToBuildTx:
            return 102000005
        case .failedToCalculateTxSize:
            return 102000006
        case .failedToConvertPublicKey:
            return 102000007
        case .failedToCreateMultisigScript:
            return 102000008
        case .failedToFindTransaction:
            return 102000009
        case .failedToFindTxInputs:
            return 102000010
        case .failedToGetFee:
            return 102000011
        case .failedToLoadFee:
            return 102000012
        case .failedToLoadTxDetails:
            return 102000013
        case .failedToParseNetworkResponse:
            return 102000014
        case .failedToSendTx:
            return 102000015
        case .feeForPushTxNotEnough:
            return 102000016
        case .networkProvidersNotSupportsRbf:
            return 102000017
        case .networkUnavailable:
            return 102000018
        case .noAPIInfo:
            return 102000019
        case .noAccount:
            return 102000020
        case .notImplemented:
            return 102000021
        case .signatureCountNotMatched:
            return 102000022
        case .twMakeAddressFailed:
            return 102000023
        case .noTrustlineAtDestination:
            return 102000024
        }
    }
}

extension AlephiumError: UniversalError {
    public var errorCode: Int {
        switch self {
        case .alphAmountOverflow:
            102001000
        case .negativeDuration:
            102001001
        case .runtime:
            102001002
        case .tokenValuesMustBeNonZero:
            102001003
        case .txOutputValueTooSmall:
            102001004
        }
    }
}

extension ScriptChunkError: UniversalError {
    public var errorCode: Int {
        switch self {
        case .error:
            102002000
        }
    }
}

extension CardanoError: UniversalError {
    public var errorCode: Int {
        switch self {
        case .assetNotFound:
            102003000
        case .derivationPathIsShort:
            102003001
        case .feeParametersNotFound:
            102003002
        case .lowAda:
            102003003
        case .noUnspents:
            102003004
        case .walletCoreError:
            102003005
        case .failedToHashTransactionData:
            102003006
        }
    }
}

extension CasperError: UniversalError {
    public var errorCode: Int {
        switch self {
        case .errorCompareCurrentByte:
            102004000
        case .errorEmptyCurrentByte:
            102004001
        case .getDataBackError:
            102004002
        case .invalidNumber:
            102004003
        case .invalidParams:
            102004004
        case .invalidURL:
            102004005
        case .methodCallError:
            102004006
        case .methodNotFound:
            102004007
        case .none:
            102004008
        case .parseError:
            102004009
        case .tooManyBytesToEncode:
            102004010
        case .undefinedDeployHash:
            102004011
        case .undefinedElement:
            102004012
        case .undefinedEncodeException:
            102004013
        case .unknown:
            102004014
        case .unsupportedCurve:
            102004015
        }
    }
}

extension ChiaError: UniversalError {
    public var errorCode: Int {
        switch self {
        case .invalidHumanReadablePart:
            102005000
        }
    }
}

extension ETHError: UniversalError {
    public var errorCode: Int {
        switch self {
        case .chainIdNotFound:
            102006000
        case .failedToGetChecksumAddress:
            102006001
        case .failedToParseAllowance:
            102006002
        case .failedToParseBalance:
            102006003
        case .failedToParseFeeHistory:
            102006004
        case .failedToParseGasLimit:
            102006005
        case .failedToParseTxCount:
            102006006
        case .gasRequiredExceedsAllowance:
            102006007
        case .invalidSourceAddress:
            102006008
        case .unsupportedFeature:
            102006009
        }
    }
}

extension FilecoinError: UniversalError {
    public var errorCode: Int {
        switch self {
        case .filecoinFeeParametersNotFound:
            102007000
        case .failedToConvertAmountToBigUInt:
            102007001
        case .failedToGetDataFromJSON:
            102007002
        }
    }
}

extension HederaError: UniversalError {
    public var errorCode: Int {
        switch self {
        case .accountBalanceNotFound:
            102008000
        case .accountDoesNotExist:
            102008001
        case .conversionFromConsensusToMirrorFailed:
            102008002
        case .conversionFromMirrorToConsensusFailed:
            102008003
        case .failedToCreateAccount:
            102008004
        case .fixedFeeInAnotherToken:
            102008005
        case .multipleAccountsFound:
            102008006
        case .transactionNotFound:
            102008007
        case .unsupportedCurve:
            102008008
        }
    }
}

extension KoinosError: UniversalError {
    public var errorCode: Int {
        switch self {
        case .contractIDIsMissing:
            102009000
        case .failedToMapKoinosDTO:
            102009001
        case .unableToDecodeChainID:
            102009002
        case .unableToParseParams:
            102009003
        }
    }
}

extension SolanaError: @retroactive UniversalError {
    public var errorCode: Int {
        switch self {
        case .blockHashNotFound:
            102010000
        case .couldNotRetriveAccountInfo:
            102010001
        case .couldNotRetriveBalance:
            102010002
        case .invalidMNemonic:
            102010003
        case .invalidPublicKey:
            102010004
        case .invalidRequest:
            102010005
        case .invalidResponse:
            102010006
        case .notFoundProgramAddress:
            102010007
        case .nullValue:
            102010008
        case .other:
            102010009
        case .socket:
            102010010
        case .unauthorized:
            102010011
        }
    }
}

extension SolanaBSDKError: UniversalError {
    public var errorCode: Int {
        switch self {
        case .transactionIsEmpty:
            102010100
        case .notImplemented:
            102010101
        }
    }
}

extension SuiError: UniversalError {
    public var errorCode: Int {
        switch self {
        case .failedDecoding:
            102011000
        case .oneSuiCoinIsRequiredForTokenTransaction:
            102011001
        }
    }
}

extension TONError: UniversalError {
    public var errorCode: Int {
        switch self {
        case .empty:
            102012000
        case .exception:
            102012001
        }
    }
}

extension TronError: UniversalError {
    public var errorCode: Int {
        switch self {
        case .failedToDecodeAddress:
            102013000
        }
    }
}

extension VeChainError: UniversalError {
    public var errorCode: Int {
        switch self {
        case .contractCallFailed:
            102014000
        case .contractCallReverted:
            102014001
        }
    }
}

extension XRPError: UniversalError {
    public var errorCode: Int {
        switch self {
        case .checksumFails:
            102015000
        case .distinctTagsFound:
            102015001
        case .failedLoadInfo:
            102015002
        case .failedLoadReserve:
            102015003
        case .failedLoadUnconfirmed:
            102015004
        case .invalidAddress:
            102015005
        case .invalidAmount:
            102015006
        case .invalidBufferSize:
            102015007
        case .invalidPrivateKey:
            102015008
        case .invalidSeed:
            102015009
        case .missingReserve:
            102015010
        case .open:
            102015011
        case .read:
            102015012
        case .failedLoadTrustLines:
            102015013
        case .failedParseAssetId:
            102015014
        }
    }
}

extension EtherscanAPIError: UniversalError {
    public var errorCode: Int {
        switch self {
        case .endOfTransactionHistoryReached:
            102016000
        case .maxRateLimitReached:
            102016001
        case .unknown:
            102016002
        }
    }
}

extension WebSocketConnectionError: UniversalError {
    public var errorCode: Int {
        switch self {
        case .invalidResponse:
            102017000
        case .webSocketNotFound:
            102017001
        case .webSocketNotFoundTask:
            102017002
        }
    }
}

extension CashAddrBech32.DecodeError: UniversalError {
    public var errorCode: Int {
        switch self {
        case .invalidCharacter:
            102018000
        case .invalidBits:
            102019000
        }
    }
}

extension TransferERC721TokenMethod.Error: UniversalError {
    public var errorCode: Int {
        switch self {
        case .invalidAssetIdentifier:
            102019000
        }
    }
}

extension TransferERC1155TokenMethod.Error: UniversalError {
    public var errorCode: Int {
        switch self {
        case .invalidAssetIdentifier:
            102020000
        }
    }
}

extension KaspaKRC20.Error: UniversalError {
    public var errorCode: Int {
        switch self {
        case .invalidIncompleteTokenTransaction:
            102021000
        case .unableToBuildRevealTransaction:
            102021001
        case .unableToFindIncompleteTokenTransaction:
            102021002
        }
    }
}

extension SS58.Error: UniversalError {
    public var errorCode: Int {
        switch self {
        case .invalidAddress:
            102023000
        }
    }
}

extension ValidationError: UniversalError {
    public var errorCode: Int {
        switch self {
        case .amountExceedsBalance:
            102024000
        case .amountExceedsFeeResourceCapacity:
            102024001
        case .balanceNotFound:
            102024002
        case .cardanoHasTokens:
            102024003
        case .cardanoInsufficientBalanceToSendToken:
            102024004
        case .destinationMemoRequired:
            102024005
        case .dustAmount:
            102024006
        case .dustChange:
            102024007
        case .feeExceedsBalance:
            102024008
        case .feeExceedsMaxFeeResource:
            102024009
        case .insufficientFeeResource:
            102024010
        case .invalidAmount:
            102024011
        case .invalidFee:
            102024012
        case .maximumUTXO:
            102024013
        case .minimumBalance:
            102024014
        case .minimumRestrictAmount:
            102024015
        case .remainingAmountIsLessThanRentExemption:
            102024016
        case .reserve:
            102024017
        case .sendingAmountIsLessThanRentExemption:
            102024018
        case .totalExceedsBalance:
            102024019
        case .noTrustlineAtDestination:
            102024020
        }
    }
}

extension JSONRPC.APIError: UniversalError {
    var errorCode: Int {
        code ?? -1
    }
}

extension YieldModuleError: UniversalError {
    public var errorCode: Int {
        switch self {
        case .unableToParseData: 102025001
        case .unsupportedBlockchain: 102025002
        case .noYieldContractFound: 102025003
        case .feeNotFound: 102025004
        case .yieldIsAlreadyActive: 102025005
        case .inconsistentState: 102025006
        case .yieldIsNotActive: 102025007
        case .maxNetworkFeeNotFound: 102025008
        case .minimalTopUpAmountNotFound: 102025009
        }
    }
}

extension BitcoinError: UniversalError {
    public var errorCode: Int {
        switch self {
        case .invalidPsbt:
            102026000
        case .invalidBase64:
            102026001
        case .unsupported:
            102026002
        case .inputIndexOutOfRange:
            102026003
        case .missingUtxo:
            102026004
        case .wrongSignaturesCount:
            102026005
        }
    }
}
