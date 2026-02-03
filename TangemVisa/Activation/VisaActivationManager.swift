//
//  VisaActivationManager.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
import TangemSdk

/// Defines a contract for managing the Visa card activation flow.
/// This manager will handle all activation process
/// At the moment of writing activation process contains three interactions with cards:
///      - First tap - initial card scan, handled by `VisaCardScanHandler`
///      - Second tap - setup Visa card and approve payment account deployment by it, handled by `CardActivationTask`
///      - Third tap - Approve payment account deployment by customer wallet, `SignHash` command, handled outside of framework
public protocol VisaActivationManager: VisaAccessCodeValidator {
    /// Address that was used to order Visa card. Use this address to find if card already added to app of while scanning another card
    /// This address must approve payment account deploy
    var targetApproveAddress: String? { get }
    /// Indicates if an access code has aleardy been set while this activation session or previous one
    /// If access code is not set it means that second tap (Visa card acceptance didn't finished previously)
    var isAccessCodeSet: Bool { get }
    /// Indicates that this is not first attempt to activate card.
    var isContinuingActivation: Bool { get }
    /// Local representation of the activation state for the Visa card.
    var activationLocalState: VisaCardActivationLocalState { get }
    /// Remote (backend-derived) representation of the Visa card's activation state.
    var activationRemoteState: VisaCardActivationRemoteState { get }

    /// Saves the provided access code for the activation session.
    /// - Parameter accessCode: A user-provided access code.
    /// - Throws: A `VisaAccessCodeValidationError` if validation fails.
    func saveAccessCode(accessCode: String) throws(VisaAccessCodeValidationError)

    /// Resets the current access code, clearing it from memory.
    func resetAccessCode()

    /// Registers a refresh token saver used to persist tokens between sessions.
    /// - Parameter refreshTokenSaver: An instance responsible for storing refresh tokens.
    func setupRefreshTokenSaver(_ refreshTokenSaver: VisaRefreshTokenSaver)

    /// Initiates or resumes the activation process based on the local state.
    /// - Returns: The response from the activation process.
    /// - Throws: A `VisaActivationError` if activation fails.
    func startActivation() async throws(VisaActivationError) -> CardActivationResponse

    /// Fetches the most recent remote activation state from the backend.
    /// - Returns: The refreshed `VisaCardActivationRemoteState`.
    /// - Throws: A `VisaActivationError` if the state cannot be retrieved.
    func refreshActivationRemoteState() async throws(VisaActivationError) -> VisaCardActivationRemoteState

    /// Loads a hash that must be signed by customer wallet to approve the payment account deployment.
    /// - Returns: A hash as `Data`.
    /// - Throws: A `VisaActivationError` if retrieval fails.
    func getCustomerWalletApproveHash() async throws(VisaActivationError) -> Data

    /// Sends a signed hash approving payment account deployment.
    /// - Parameter signedData: Signed acceptance by customer wallet.
    /// - Throws: A `VisaActivationError` if the request fails.
    func sendSignedCustomerWalletApprove(_ signedData: Data) async throws(VisaActivationError)

    /// Submits selected PIN code to the issuer.
    /// - Parameter pinCode: The selected PIN code.
    /// - Throws: A `VisaActivationError` if the process fails.
    func setPINCode(_ pinCode: String) async throws(VisaActivationError)
}

/// Validates access codes used in the Visa activation flow.
public protocol VisaAccessCodeValidator: AnyObject {
    /// Validates that an access code meets format requirements.
    /// - Parameter accessCode: The access code to validate.
    /// - Throws: A `VisaAccessCodeValidationError` if validation fails.
    func validateAccessCode(accessCode: String) throws(VisaAccessCodeValidationError)
}

/// The default implementation of `VisaActivationManager`.
/// Handles state transitions, access code management, remote state syncing, and backend communication during Visa card activation.
final class CommonVisaActivationManager {
    /// Represents the current local state of the Visa card activation process.
    /// This includes information such as whether the card is activated, blocked, or awaiting signature.
    public private(set) var activationLocalState: VisaCardActivationLocalState

    /// The customer wallet address that must approve payment account deployment.
    /// This can be Tangem wallet or any other wallet that was used to order a Visa card
    /// - Returns: `nil` if no activation status is available or customer wallet address didn't registered for order (issue on backend side).
    public var targetApproveAddress: String? {
        guard let activationOrder = activationStatus?.activationOrder else {
            return nil
        }

        return activationOrder.customerWalletAddress
    }

    public var activationRemoteState: VisaCardActivationRemoteState {
        switch activationLocalState {
        case .activated:
            return .activated
        case .activationStarted(_, _, let activationStatus):
            return activationStatus.activationRemoteState
        case .notStartedActivation:
            return .cardWalletSignatureRequired
        case .blocked:
            return .blockedForActivation
        }
    }

    private let isTestnet: Bool
    private var selectedAccessCode: String?
    private var lastLoadedActivationStatus: VisaCardActivationStatus?

    private let authorizationTokensHandler: VisaAuthorizationTokensHandler
    private let tangemSdk: TangemSdk

    private let authorizationProcessor: CardAuthorizationProcessor
    private let cardActivationOrderProvider: CardActivationOrderProvider
    private let cardActivationStatusService: VisaCardActivationStatusService
    private let productActivationService: ProductActivationService
    private let otpRepository: VisaOTPRepository
    private let pinCodeProcessor: PINCodeProcessor

    private var activationStatus: VisaCardActivationStatus? {
        switch activationLocalState {
        case .activated, .notStartedActivation, .blocked:
            return nil
        case .activationStarted(_, _, let activationStatus):
            return activationStatus
        }
    }

    /// Information about the activating card.`nil` if card is already in activated state or blocked for activation
    private var activationInput: VisaCardActivationInput? {
        activationLocalState.activationInput
    }

    init(
        isTestnet: Bool,
        initialActivationStatus: VisaCardActivationLocalState,
        authorizationTokensHandler: VisaAuthorizationTokensHandler,
        tangemSdk: TangemSdk,
        authorizationProcessor: CardAuthorizationProcessor,
        cardActivationOrderProvider: CardActivationOrderProvider,
        cardActivationStatusService: VisaCardActivationStatusService,
        productActivationService: ProductActivationService,
        otpRepository: VisaOTPRepository,
        pinCodeProcessor: PINCodeProcessor
    ) {
        self.isTestnet = isTestnet
        activationLocalState = initialActivationStatus

        self.authorizationTokensHandler = authorizationTokensHandler
        self.tangemSdk = tangemSdk

        self.authorizationProcessor = authorizationProcessor
        self.cardActivationOrderProvider = cardActivationOrderProvider
        self.cardActivationStatusService = cardActivationStatusService
        self.productActivationService = productActivationService
        self.otpRepository = otpRepository
        self.pinCodeProcessor = pinCodeProcessor
    }
}

extension CommonVisaActivationManager: VisaActivationManager {
    var isAccessCodeSet: Bool {
        guard let activationInput else {
            return true
        }

        return activationInput.isAccessCodeSet
    }

    var isContinuingActivation: Bool {
        if case .notStartedActivation = activationLocalState {
            return false
        }

        return true
    }

    func validateAccessCode(accessCode: String) throws(VisaAccessCodeValidationError) {
        guard accessCode.count >= 4 else {
            throw .accessCodeIsTooShort
        }
    }

    func saveAccessCode(accessCode: String) throws(VisaAccessCodeValidationError) {
        try validateAccessCode(accessCode: accessCode)

        selectedAccessCode = accessCode
    }

    func resetAccessCode() {
        selectedAccessCode = nil
    }

    func setupRefreshTokenSaver(_ refreshTokenSaver: VisaRefreshTokenSaver) {
        authorizationTokensHandler.setupRefreshTokenSaver(refreshTokenSaver)
    }

    func startActivation() async throws(VisaActivationError) -> CardActivationResponse {
        switch activationLocalState {
        case .activated:
            throw .alreadyActivated
        case .activationStarted(let activationInput, let authorizationTokens, let status):
            guard status.activationRemoteState == .cardWalletSignatureRequired else {
                throw .invalidActivationState
            }

            return try await continueActivation(activationInput: activationInput, authorizationTokens: authorizationTokens)
        case .notStartedActivation(let activationInput):
            guard let selectedAccessCode else {
                throw .missingAccessCode
            }

            return try await startFullActivationFlow(activationInput: activationInput, accessCodeSetupType: .newAccessCode(accessCode: selectedAccessCode))
        case .blocked:
            throw .blockedForActivation
        }
    }

    /// Fetches the most recent remote activation state from the backend.
    /// - Returns: The refreshed `VisaCardActivationRemoteState`.
    /// - Throws: A `VisaActivationError` if the state cannot be retrieved.
    func refreshActivationRemoteState() async throws(VisaActivationError) -> VisaCardActivationRemoteState {
        guard let authorizationTokens = authorizationTokensHandler.authorizationTokens else {
            throw .missingAccessToken
        }

        guard let activationInput else {
            throw .invalidActivationState
        }

        let loadedStatus: VisaCardActivationStatus
        do {
            loadedStatus = try await cardActivationStatusService.getCardActivationStatus(
                cardId: activationInput.cardId,
                cardPublicKey: activationInput.cardPublicKey.hexString
            )
        } catch {
            throw .underlyingError(error)
        }

        let loadedState = loadedStatus.activationRemoteState

        guard loadedState != activationRemoteState else {
            return loadedState
        }

        // Check if new status is not related to PIN validation
        var pinStatusError: VisaActivationError?
        do {
            try checkPinStatus(newStatus: loadedStatus)
        } catch {
            pinStatusError = error
        }

        lastLoadedActivationStatus = loadedStatus

        updateActivationStatus(
            toState: loadedState,
            using: activationInput,
            authorizationTokens: authorizationTokens
        )

        if let pinStatusError {
            throw pinStatusError
        }

        if case .activated = loadedState {
            try await saveActivatedCardRefreshToken()
        }

        return loadedState
    }

    /// Loads a hash that must be signed by customer wallet to approve the payment account deployment.
    /// - Returns: A hash as `Data`.
    /// - Throws: A `VisaActivationError` if retrieval fails. Also can fail if didn't found wallet address after Visa card approval or during initial card scan
    func getCustomerWalletApproveHash() async throws(VisaActivationError) -> Data {
        guard let activationStatus else {
            throw .missingActivationStatusInfo
        }

        guard let activationOrder = activationStatus.activationOrder else {
            throw .missingActivationOrder
        }

        guard let walletAddress = activationInput?.walletAddress else {
            throw .missingWalletAddressInInput
        }

        VisaLogger.info("Attempting to get challenge to approve by customer wallet")
        do {
            let customerWalletApproveResponse = try await productActivationService.getCustomerWalletDeployAcceptance(
                activationOrderId: activationOrder.id,
                customerWalletAddress: activationOrder.customerWalletAddress,
                cardWalletAddress: walletAddress
            )
            return Data(hexString: customerWalletApproveResponse)
        } catch {
            VisaLogger.error("Failed to load customer wallet approve hash", error: error)
            throw .underlyingError(error)
        }
    }

    /// Sends a signed hash approving payment account deployment.
    /// - Parameter signedData: Signed acceptance by customer wallet.
    /// - Throws: A `VisaActivationError` if the request fails.
    func sendSignedCustomerWalletApprove(_ signedData: Data) async throws(VisaActivationError) {
        guard let activationInput else {
            throw .missingActivationInput
        }

        guard let activationOrder = activationStatus?.activationOrder else {
            throw .missingActivationStatusInfo
        }

        guard let authorizationTokens = authorizationTokensHandler.authorizationTokens else {
            throw .missingAccessToken
        }

        VisaLogger.info("Receive signed approve by customer wallet. Attempting to send it")
        do {
            try await productActivationService.sendSignedCustomerWalletDeployAcceptance(
                activationOrderId: activationOrder.id,
                customerWalletAddress: activationOrder.customerWalletAddress,
                deployAcceptanceSignature: signedData.hexString
            )
        } catch {
            VisaLogger.error("Failed to send signed customer wallet approve data", error: error)
            throw .underlyingError(error)
        }

        updateActivationStatus(
            toState: .paymentAccountDeploying,
            using: activationInput,
            authorizationTokens: authorizationTokens
        )
    }

    /// Submits selected PIN code to the issuer.
    /// - Parameter pinCode: The selected PIN code.
    /// - Throws: A `VisaActivationError` if the process fails.
    func setPINCode(_ pinCode: String) async throws(VisaActivationError) {
        guard
            let activationInput,
            let authorizationTokens = authorizationTokensHandler.authorizationTokens,
            let activationOrderId = activationStatus?.activationOrder?.id
        else {
            throw .missingAccessToken
        }

        VisaLogger.info("Attempting to send selected PIN code")
        do {
            let processedPINCode = try await pinCodeProcessor.processSelectedPINCode(pinCode)

            try await productActivationService.sendSelectedPINCodeToIssuer(
                activationOrderId: activationOrderId,
                sessionKey: processedPINCode.sessionKey,
                iv: processedPINCode.iv,
                encryptedPin: processedPINCode.encryptedPIN
            )
        } catch {
            VisaLogger.error("Failed to send selected PIN to issuer", error: error)
            throw .underlyingError(error)
        }

        updateActivationStatus(toState: .waitingForActivationFinishing, using: activationInput, authorizationTokens: authorizationTokens)
    }
}

// MARK: - Task implementation

extension CommonVisaActivationManager: CardActivationTaskDelegate {
    /// Send signed authorization challenge to BFF to acquire authorization tokens. Loaded tokens will be stored in tokens handler
    /// - Parameters:
    ///   - signedAuthorizationChallenge: The signed authorization challenge used to load access token that will be used to access BFF.
    ///   - completion: Completion handler returning Void if authorization was successful and error otherwise
    func processAuthorizationChallenge(
        signedAuthorizationChallenge: AttestCardKeyResponse,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        runTask(in: self, isDetached: false) { manager in
            do {
                guard let cardInput = manager.activationInput else {
                    throw VisaActivationError.alreadyActivated
                }

                let tokens = try await manager.authorizationProcessor.getAccessToken(
                    signedChallenge: signedAuthorizationChallenge.cardSignature,
                    salt: signedAuthorizationChallenge.salt,
                    cardInput: cardInput
                )
                try await manager.authorizationTokensHandler.setupTokens(tokens)
                completion(.success(()))
            } catch {
                VisaLogger.error("Failed to get authorization tokens", error: error)
                completion(.failure(error))
            }
        }
    }

    /// Requests an activation order from the BFF for taget wallet address
    /// - Parameter completion: Completion handler returning the activation order or an error.
    func getActivationOrder(walletAddress: String, completion: @escaping (Result<VisaCardAcceptanceOrderInfo, any Error>) -> Void) {
        runTask(in: self, isDetached: false) { manager in
            do {
                guard let cardInput = manager.activationInput else {
                    throw VisaActivationError.alreadyActivated
                }

                let activationOrder = try await manager.cardActivationOrderProvider.provideActivationOrderForSign(walletAddress: walletAddress, activationInput: cardInput)
                completion(.success(activationOrder))
            } catch {
                VisaLogger.error("Failed to load activation order", error: error)
                completion(.failure(error))
            }
        }
    }
}

private extension CommonVisaActivationManager {
    /// Performs the full activation flow for new empty Visa card, retrieving authorization tokens (access and refresh), signing acceptance by Visa card and OTP generation
    /// - Parameters:
    ///   - activationInput: Initial input containing card and wallet details.
    ///   - accessCode: The access code provided by the user.
    /// - Returns: A `CardActivationResponse` object containing the result of the activation process.
    /// - Throws: `VisaActivationError` if any step of the flow fails.
    func startFullActivationFlow(
        activationInput: VisaCardActivationInput,
        accessCodeSetupType: CardActivationTask.AccessCodeSetupType
    ) async throws(VisaActivationError) -> CardActivationResponse {
        do {
            var authorizationChallenge: String?
            if !authorizationTokensHandler.containsAccessToken {
                authorizationChallenge = try await authorizationProcessor.getAuthorizationChallenge(for: activationInput)
            }

            let task = CardActivationTask(
                accessCodeSetupType: accessCodeSetupType,
                activationInput: activationInput,
                isTestnet: isTestnet,
                authorizationChallengeToSign: authorizationChallenge,
                delegate: self,
                otpRepository: otpRepository
            )

            let activationResponse: CardActivationResponse = try await withCheckedThrowingContinuation { [weak self] continuation in
                guard let self else {
                    continuation.resume(throwing: "Deinitialized")
                    return
                }

                tangemSdk.startSession(with: task, cardId: activationInput.cardId) { result in
                    switch result {
                    case .success(let response):
                        continuation.resume(with: .success(response))
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            }

            let newInput = try VisaCardActivationInput(
                cardInput: activationInput,
                cardActivationResponse: activationResponse,
                isTestnet: isTestnet
            )

            guard let tokens = authorizationTokensHandler.authorizationTokens else {
                throw VisaActivationError.missingAccessToken
            }

            activationLocalState = .activationStarted(
                activationInput: newInput,
                authTokens: tokens,
                activationStatus: .init(
                    activationRemoteState: .cardWalletSignatureRequired,
                    activationOrder: activationResponse.signedActivationOrder.order.activationOrder
                )
            )
            try await handleCardActivation(using: activationResponse, activationInput: newInput)
            return activationResponse
        } catch {
            VisaLogger.error("Failed to activate card", error: error)
            throw .underlyingError(error)
        }
    }

    /// Continues the activation process depending on the access code presence. If card didn't have access code we need to start full activation flow
    /// - Parameters:
    ///   - activationInput: Card and wallet context.
    ///   - authorizationTokens: Tokens needed for authorized BFF requests.
    /// - Returns: A `CardActivationResponse` object.
    /// - Throws: `VisaActivationError` on failure or missing data.
    func continueActivation(
        activationInput: VisaCardActivationInput,
        authorizationTokens: VisaAuthorizationTokens
    ) async throws(VisaActivationError) -> CardActivationResponse {
        do {
            if activationInput.isAccessCodeSet {
                guard otpRepository.hasSavedOTP(cardId: activationInput.cardId) else {
                    return try await startFullActivationFlow(activationInput: activationInput, accessCodeSetupType: .alreadySet)
                }

                return try await signActivationOrder(activationInput: activationInput)
            } else {
                guard let selectedAccessCode else {
                    throw VisaActivationError.missingAccessCode
                }

                return try await startFullActivationFlow(activationInput: activationInput, accessCodeSetupType: .newAccessCode(accessCode: selectedAccessCode))
            }
        } catch let activationError as VisaActivationError {
            throw activationError
        } catch {
            throw .underlyingError(error)
        }
    }

    /// Signs the activation order with the Visa card and prepares the activation response.
    /// This step includes only acceptance signing because in previous attempt user already setup access code (the final step of Visa card setup)
    /// but something went wrong during interacting with BFF and backend didn't received signed acceptance
    /// - Parameter activationInput: Card input used to generate the activation order.
    /// - Returns: A completed `CardActivationResponse`.
    /// - Throws: An error if signing fails or session cannot be started.
    func signActivationOrder(activationInput: VisaCardActivationInput) async throws -> CardActivationResponse {
        guard let walletAddress = activationInput.walletAddress else {
            throw VisaActivationError.missingWalletAddressInInput
        }

        let activationOrder = try await cardActivationOrderProvider.provideActivationOrderForSign(walletAddress: walletAddress, activationInput: activationInput)

        let signTask = SignActivationOrderTask(orderToSign: activationOrder)
        let signedActivationOrder: SignedActivationOrder = try await withCheckedThrowingContinuation { [weak self] continuation in
            guard let self else {
                continuation.resume(throwing: "Deinitialized")
                return
            }

            tangemSdk.startSession(with: signTask, cardId: activationInput.cardId) { result in
                switch result {
                case .success(let signedOrder):
                    continuation.resume(returning: signedOrder)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }

        guard let storedOTP = otpRepository.getOTP(cardId: activationInput.cardId) else {
            throw VisaActivationError.missingRootOTP
        }

        let activationResponse = CardActivationResponse(
            signedActivationOrder: signedActivationOrder,
            rootOTP: storedOTP.rootOTP,
            rootOTPCounter: storedOTP.rootOTPCounter
        )
        let newActivationInput = try VisaCardActivationInput(
            cardInput: activationInput,
            cardActivationResponse: activationResponse,
            isTestnet: isTestnet
        )
        try await handleCardActivation(using: activationResponse, activationInput: newActivationInput)
        return activationResponse
    }

    /// Sends the signed deploy acceptance and updates activation state accordingly.
    /// - Parameters:
    ///   - activationResponse: Contains the signed activation order and OTP info.
    ///   - activationInput: The card's activation context.
    /// - Throws: `VisaActivationError` if deployment submission fails.
    func handleCardActivation(using activationResponse: CardActivationResponse, activationInput: VisaCardActivationInput) async throws(VisaActivationError) {
        guard let tokens = authorizationTokensHandler.authorizationTokens else {
            throw .missingAccessToken
        }

        guard let walletAddress = activationInput.walletAddress else {
            throw .missingWalletAddressInInput
        }

        VisaLogger.info("Attempting to send deploy acceptance signed by card")
        do {
            let order = activationResponse.signedActivationOrder.order.activationOrder
            try await productActivationService.sendSignedVisaCardDeployAcceptance(
                activationOrderId: order.id,
                cardWalletAddress: walletAddress,
                signedAcceptance: activationResponse.signedActivationOrder.signedOrderByWallet.hexString,
                rootOtp: activationResponse.rootOTP.hexString,
                rootOtpCounter: activationResponse.rootOTPCounter
            )
        } catch {
            VisaLogger.error("Failed to send deploy acceptance signed by card", error: error)
            throw .underlyingError(error)
        }

        activationLocalState = .activationStarted(
            activationInput: activationInput,
            authTokens: tokens,
            activationStatus: .init(
                activationRemoteState: .customerWalletSignatureRequired,
                activationOrder: activationResponse.signedActivationOrder.order.activationOrder
            )
        )
    }

    /// Forces a refresh of the authorization tokens after card activation. Backend have two type of authorization tokens:
    ///     - tokens for activation process
    ///     - tokens for activated card
    /// That is why we need to force refresh token, to retreive tokens for activated card
    /// - Throws: `VisaActivationError` if token refresh fails.
    func saveActivatedCardRefreshToken() async throws(VisaActivationError) {
        do {
            try await authorizationTokensHandler.exchageTokens()
        } catch {
            VisaLogger.error("Failed to retreive activated card refresh token", error: error)
            throw .underlyingError(error)
        }
    }
}

// MARK: - Activation status handling

private extension CommonVisaActivationManager {
    /// Evaluates whether a backend-reported PIN failure has occurred based on updated activation status.
    /// - Parameter newStatus: Newly retrieved activation status.
    /// - Throws: `VisaActivationError.paymentologyPinError` if PIN is detected as invalid.
    func checkPinStatus(newStatus: VisaCardActivationStatus) throws(VisaActivationError) {
        // If BFF returns stepChangeCode for waitingPinCode state it means that external service
        // mark selected PIN code as invalid and we need to show user an error of invalid PIN
        let invalidPinStepChangeCode = CardActivationOrderStepChangeCode.pinValidation.rawValue
        guard
            newStatus.activationOrder?.stepChangeCode == invalidPinStepChangeCode,
            newStatus.activationRemoteState == .waitingPinCode
        else {
            return
        }

        guard let lastLoadedActivationStatus else {
            // If after first update of status we receive stepChangeCode we already know
            // that PIN validation was failed on extenral service
            throw .paymentologyPinError
        }

        switch lastLoadedActivationStatus.activationRemoteState {
        case .waitingPinCode, .waitingForActivationFinishing:
            // If previous stored activation state is related to PIN we need to check if dates are the same
            break
        default:
            // If previous stored activation state not related to PIN code we continue state validation
            return
        }

        guard lastLoadedActivationStatus.activationOrder?.updatedAt == newStatus.activationOrder?.updatedAt else {
            throw .paymentologyPinError
        }

        if newStatus.activationRemoteState == .waitingPinCode {
            throw .paymentologyPinError
        }
    }
}

private extension CommonVisaActivationManager {
    /// Updates the local activation state according to remote state and current auth tokens.
    /// - Parameters:
    ///   - state: The latest remote activation state.
    ///   - input: Card activation input used to preserve context.
    ///   - authorizationTokens: Valid access and refresh tokens.
    func updateActivationStatus(
        toState state: VisaCardActivationRemoteState,
        using input: VisaCardActivationInput,
        authorizationTokens: VisaAuthorizationTokens?
    ) {
        // [REDACTED_TODO_COMMENT]
        guard
            let authorizationTokens,
            let activationStatus
        else {
            activationLocalState = .notStartedActivation(activationInput: input)
            return
        }

        switch state {
        case .cardWalletSignatureRequired:
            if input.isAccessCodeSet {
                activationLocalState = .activationStarted(
                    activationInput: input,
                    authTokens: authorizationTokens,
                    activationStatus: .init(activationRemoteState: state, activationOrder: activationStatus.activationOrder)
                )
            } else {
                activationLocalState = .notStartedActivation(activationInput: input)
            }
        case .blockedForActivation, .failed:
            activationLocalState = .blocked
        case .activated:
            activationLocalState = .activated(authTokens: authorizationTokens)
        case .customerWalletSignatureRequired, .paymentAccountDeploying, .waitingForActivationFinishing, .waitingPinCode:
            activationLocalState = .activationStarted(
                activationInput: input,
                authTokens: authorizationTokens,
                activationStatus: .init(activationRemoteState: state, activationOrder: activationStatus.activationOrder)
            )
        }
    }
}
