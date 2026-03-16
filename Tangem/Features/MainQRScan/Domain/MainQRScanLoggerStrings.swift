//
//  MainQRScanLoggerStrings.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

enum MainQRScanLoggerStrings {
    // MARK: - Coordinator

    static let coordinatorReceivedScanResult = "Coordinator received scan result from view model"

    // MARK: - Flow coordinator

    static func qrScanCoordinatorUpdated(isNil: Bool) -> String {
        "qrScanCoordinator updated. isNil=\(isNil)"
    }

    static let qrScannerClosedByUser = "QR scanner closed by user"
    static let flowCoordinatorReceivedScanResult = "Flow coordinator received scan result"
    static let flowCoordinatorStartedBackgroundResolve = "Flow coordinator started QR route resolve on background queue"

    static func flowCoordinatorResolvedAction(_ actionName: String) -> String {
        "Flow coordinator resolved action=\(actionName)"
    }

    static func flowCoordinatorRoutingAction(_ actionName: String) -> String {
        "Flow coordinator routing action=\(actionName)"
    }

    static let walletConnectActionSelected = "WalletConnect action selected"
    static let paymentSingleActionSelected = "paymentSingle action selected"
    static let paymentMultipleActionSelected = "paymentMultiple action selected"
    static let addressSingleActionSelected = "addressSingle action selected"
    static let addressMultipleActionSelected = "addressMultiple action selected"
    static let showingUnrecognizedAlert = "Showing unrecognized QR alert and keeping scanner open"
    static let showingUnsupportedNetworkAlert = "Showing unsupported network alert and keeping scanner open"
    static let showingUnsupportedRecognizedRouteAlert = "Recognized route is not supported yet. Showing alert and keeping scanner open"

    // MARK: - View model

    static let ignoredScanResultWaitingForRearm = "Ignored scan result because scanner is waiting for rearm"
    static let qrScannedFromCamera = "QR scanned from camera"
    static let qrPayloadPastedFromClipboard = "QR payload pasted from clipboard"
    static let scannerRearmed = "Scanner rearmed and ready for next scan"
    static let scannerSessionFailed = "Scanner session failed. Showing recovery options."
    static let noPayloadExtractedFromImage = "No QR payload extracted from selected image"
    static let failedToToggleFlash = "Failed to toggle the flash"

    // MARK: - Flow handler

    static func flowHandlerStarted(availableBlockchains: Int) -> String {
        "Flow handler started. availableBlockchains=\(availableBlockchains)"
    }

    static func flowHandlerResolvedAction(_ actionName: String) -> String {
        "Flow handler resolved action=\(actionName)"
    }

    static func collectingWalletTokenItems(userWalletModels: Int) -> String {
        "Collecting wallet token items. userWalletModels=\(userWalletModels)"
    }

    static func collectedWalletModels(walletModels: Int) -> String {
        "Collected wallet models from one wallet. walletModels=\(walletModels)"
    }

    static let noWalletTokenItemsCollected = "No wallet token items collected. Wallet may be locked or have no tokens."

    // MARK: - Route resolver

    static func routeResolverStarted(availableBlockchains: Int) -> String {
        "Route resolver started. availableBlockchains=\(availableBlockchains)"
    }

    static let routeResolverMatchedWalletConnect = "Route resolver matched walletConnect"
    static let routeResolverMatchedPaymentURI = "Route resolver matched paymentURI"
    static let routeResolverTreatingPaymentAsAddress = "Route resolver treats payment URI as address-only payload"
    static let routeResolverMatchedPlainAddress = "Route resolver matched plainAddress"
    static let routeResolverMatchedUnrecognizedPayload = "Route resolver matched unrecognized payload"
    static let paymentQRParsedWithoutAvailableBlockchains = "Payment QR parsed, but no available blockchains loaded in repository."

    static func paymentRouteResolutionByTokenContract(tokenMatches: Int) -> String {
        "Payment route resolution by token contract. tokenMatches=\(tokenMatches)"
    }

    static func paymentRouteResolutionFinished(matches: Int) -> String {
        "Payment route resolution finished. matches=\(matches)"
    }

    static let addressQRGloballyValidWithoutAvailableBlockchains = "Address QR is globally valid, but no available blockchains loaded in repository."

    static func addressRouteResolutionFinished(compatibleBlockchains: Int, matches: Int) -> String {
        "Address route resolution finished. compatibleBlockchains=\(compatibleBlockchains), matches=\(matches)"
    }

    // MARK: - Parser

    static let parserStarted = "Parser started"
    static let parserResultUnrecognizedEmptyPayload = "Parser result=unrecognized (empty payload)"
    static let parserResultWalletConnect = "Parser result=walletConnect"
    static let parserResultPaymentURIBlockchainURI = "Parser result=paymentURI via blockchain URI"
    static let parserResultPaymentURIJSON = "Parser result=paymentURI via JSON"
    static let parserResultPaymentURIDeepLink = "Parser result=paymentURI via deep link"
    static let parserResultUnrecognizedHTTP = "Parser result=unrecognized (plain http/https)"
    static let parserResultPlainAddress = "Parser result=plainAddress"

    // MARK: - Address resolver

    static func addressResolverStarted(addressLength: Int, blockchains: Int) -> String {
        "Address resolver started. addressLength=\(addressLength), blockchains=\(blockchains)"
    }

    static func addressResolverFinished(matchedCount: Int) -> String {
        "Address resolver finished. matchedCount=\(matchedCount)"
    }
}
