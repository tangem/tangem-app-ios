//
//  VisaAPIMocks.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import TangemSdk

public protocol VisaMockMenuPresenter {
    func modalFromTop(_ vc: UIViewController)
}

public class VisaMocksManager {
    public static let instance = VisaMocksManager()

    private(set) var activationRemoteState: VisaCardActivationRemoteState = .cardWalletSignatureRequired
    private(set) var customerWalletAddress: String = "0x9F65354e595284956599F2892fA4A4a87653D6E6"
    lazy var activationOrder: VisaCardActivationOrder = validActivationOrder
    var validActivationOrder: VisaCardActivationOrder {
        .init(
            id: "f30bee47-21b6-4d07-9492-a5f2e0542875",
            customerId: "f89a0b9e-e5ae-4c34-b0cd-f335f5c2a9f3",
            customerWalletAddress: customerWalletAddress,
            cardWalletAddress: "",
            updatedAt: nil,
            stepChangeCode: nil
        )
    }

    var invalidPinActivationOrder: VisaCardActivationOrder {
        .init(
            id: "invalid-pin-order",
            customerId: "f89a0b9e-e5ae-4c34-b0cd-f335f5c2a9f3",
            customerWalletAddress: customerWalletAddress,
            cardWalletAddress: "",
            updatedAt: Date(),
            stepChangeCode: 1000
        )
    }

    var isWalletAuthorizationTokenEnabled: Bool {
        activationRemoteState == .activated
    }

    private init() {}

    public func showMocksMenu(openSupportAction: @escaping () -> Void, presenter: VisaMockMenuPresenter) {
        let actions: [UIAlertAction] = [
            UIAlertAction(
                title: "Card activation remote state",
                style: .default
            ) { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.changeCardActivationRemoteState(presenter)
                }
            },
            UIAlertAction(
                title: "Wallet Authorization Token availability",
                style: .default
            ) { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.changeWalletAuthorizationTokenAvailability(presenter)
                }
            },
            UIAlertAction(
                title: "Select customer wallet address",
                style: .default
            ) { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.changeCustomerWalletAddress(presenter)
                }
            },
            UIAlertAction(
                title: "Change activation order",
                style: .default,
                handler: { _ in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self.changeActivationOrder(presenter)
                    }
                }
            ),
            UIAlertAction(
                title: "Open Support",
                style: .default,
                handler: { _ in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        openSupportAction()
                    }
                }
            ),
        ]
        let actionSheet = buildActionSheet(
            title: "Select setting to toggle",
            message: "Actions will open additional action sheet with available settings",
            actions: actions
        )
        presenter.modalFromTop(actionSheet)
    }

    func changeCardActivationRemoteState(_ presenter: VisaMockMenuPresenter) {
        let actions: [UIAlertAction] = VisaCardActivationRemoteState.allCases.map { state in
            UIAlertAction(
                title: state.rawValue,
                style: .default
            ) { _ in
                self.changeActivationRemoteState(to: state)
            }
        }
        let actionSheet = buildActionSheet(
            title: "Card activation remote state",
            message: "Select new card activation state. It will be used in all mocked responses until changed again in this menu",
            actions: actions
        )
        presenter.modalFromTop(actionSheet)
    }

    func changeWalletAuthorizationTokenAvailability(_ presenter: VisaMockMenuPresenter) {
        let actions: [UIAlertAction] = [
            .init(title: "Enabled", style: .default) { _ in
                self.changeActivationRemoteState(to: .activated)
            },
            .init(title: "Disabled", style: .default) { _ in
                self.changeActivationRemoteState(to: .cardWalletSignatureRequired)
            },
        ]
        let actionSheet = buildActionSheet(
            title: "Change Wallet authorization token availability",
            message: "When set to enabled - mocked API will return remote state `.activated`\nWhen set to disabled - mocked API will return remote state `.cardWalletSignatureRequired`",
            actions: actions
        )
        presenter.modalFromTop(actionSheet)
    }

    func changeCustomerWalletAddress(_ presenter: VisaMockMenuPresenter) {
        let alertController = UIAlertController(
            title: "Enter new customer wallet address",
            message: "Current Customer Wallet Address is: \(customerWalletAddress)",
            preferredStyle: .alert
        )

        alertController.addTextField { textField in
            textField.placeholder = "Customer wallet address..."
            textField.keyboardType = .default
        }

        let confirmAction = UIAlertAction(title: "Confirm", style: .default) { _ in
            guard let textField = alertController.textFields?.first,
                  let text = textField.text, !text.isEmpty else {
                return
            }

            self.customerWalletAddress = text
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in }

        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)

        presenter.modalFromTop(alertController)
    }

    func changeActivationOrder(_ presenter: VisaMockMenuPresenter) {
        let actions: [UIAlertAction] = [
            .init(title: "Default activation order", style: .default, handler: { _ in
                self.activationOrder = self.validActivationOrder
            }),
            .init(title: "Invalid pin activation order", style: .default, handler: { _ in
                self.activationOrder = self.invalidPinActivationOrder
            }),
        ]

        let currentOrderName = activationOrder.id == invalidPinActivationOrder.id ? "Invalid PIN order" :
            activationOrder.id == validActivationOrder.id ? "Default Activation Order" :
            "Unknown Activation order"
        let actionSheet = buildActionSheet(
            title: "Change activation order",
            message: "When Invalid PIN activation order is selected app will navigate from in progress screen to enter PIN code screen with error. Select invalid PIN order when you need to check PIN validation on the external service side. Current order: \(currentOrderName)",
            actions: actions
        )
        presenter.modalFromTop(actionSheet)
    }

    func changeActivationRemoteState(to newState: VisaCardActivationRemoteState) {
        activationRemoteState = newState
    }

    private func buildActionSheet(title: String, message: String, actions: [UIAlertAction]) -> UIViewController {
        let vc = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .actionSheet
        )

        actions.forEach { vc.addAction($0) }

        vc.addAction(.init(title: "Cancel", style: .cancel))
        return vc
    }
}

struct AuthorizationServiceMock: VisaAuthorizationService, VisaAuthorizationTokenRefreshService {
    let authorizationTokens = VisaAuthorizationTokens(
        accessToken: "eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCIsImtpZCI6IjY1MDIyMGEzLWUyYWItNDUwMS04MTA4LWY3ZDUyNDAzNWQ1MSJ9.eyJleHAiOjE3ODM2Njk0MzEsImlhdCI6MTcyNjY2NjgxMSwianRpIjoiY2JkNGVkMzQtZjY0OS00ZmY5LThhYzAtYjllYWFhZDVlYjY0IiwiaXNzIjoiaHR0cDovL2xvY2FsaG9zdDo4MDgwL3JlYWxtcy90ZXN0IiwiYXVkIjoiaHR0cDovL2xvY2FsaG9zdDo4MDgwL3JlYWxtcy90ZXN0Iiwic3ViIjoiZjo0MzNjNDRkYS0wYThlLTQ5NjktYmM0Yi1iMDgxZThiNDViN2Y6ZjdkNmZmNzQtMjk2MS00YmQ0LThlZTItOTczZjE2ZTlkNGM0IiwidHlwIjoiUmVmcmVzaCIsImF6cCI6InRlc3QiLCJzaWQiOiIzYmI4NjUxMy0xYTNiLTRmZmMtOTJmOC02ODU5ZjhhMDQyMDEiLCJzY29wZSI6ImJhc2ljIHJvbGVzIGFjciB3ZWItb3JpZ2lucyIsInByb2R1Y3QtaW5zdGFuY2UtaWQiOiI0MzQzZmVta2ZscmV3Z2lydnctM2V4MjMiLCJjdXN0b21lci1pZCI6IjQzMnJodXJmaGcyOTU0dGg0ODkifQ.6iOH-4eNL9bs6wwId-nQNqIC7rUAgmD47N8oUPz2Wz2Ajz3YiZOa6PBsyqlcwB_xPHTvdYQs6OsY-p9Ahaq6Tg",
        refreshToken: "eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCIsImtpZCI6IjY1MDIyMGEzLWUyYWItNDUwMS04MTA4LWY3ZDUyNDAzNWQ1MSJ9.eyJleHAiOjE3ODM2Njk0MzEsImlhdCI6MTcyNjY2NjgxMSwianRpIjoiY2JkNGVkMzQtZjY0OS00ZmY5LThhYzAtYjllYWFhZDVlYjY0IiwiaXNzIjoiaHR0cDovL2xvY2FsaG9zdDo4MDgwL3JlYWxtcy90ZXN0IiwiYXVkIjoiaHR0cDovL2xvY2FsaG9zdDo4MDgwL3JlYWxtcy90ZXN0Iiwic3ViIjoiZjo0MzNjNDRkYS0wYThlLTQ5NjktYmM0Yi1iMDgxZThiNDViN2Y6ZjdkNmZmNzQtMjk2MS00YmQ0LThlZTItOTczZjE2ZTlkNGM0IiwidHlwIjoiUmVmcmVzaCIsImF6cCI6InRlc3QiLCJzaWQiOiIzYmI4NjUxMy0xYTNiLTRmZmMtOTJmOC02ODU5ZjhhMDQyMDEiLCJzY29wZSI6ImJhc2ljIHJvbGVzIGFjciB3ZWItb3JpZ2lucyIsInByb2R1Y3QtaW5zdGFuY2UtaWQiOiI0MzQzZmVta2ZscmV3Z2lydnctM2V4MjMiLCJjdXN0b21lci1pZCI6IjQzMnJodXJmaGcyOTU0dGg0ODkifQ.6iOH-4eNL9bs6wwId-nQNqIC7rUAgmD47N8oUPz2Wz2Ajz3YiZOa6PBsyqlcwB_xPHTvdYQs6OsY-p9Ahaq6Tg",
        authorizationType: .cardId
    )

    func getCardAuthorizationChallenge(cardId: String, cardPublicKey: String) async throws -> VisaAuthChallengeResponse {
        return .init(
            nonce: RandomBytesGenerator().generateBytes(length: 16).hexString,
            sessionId: "e98b782c3a32329de53d78d16da7bf0c=e98b782c3a32329de53d78d16da7bf0c=="
        )
    }

    func getWalletAuthorizationChallenge(cardId: String, walletPublicKey: String) async throws -> VisaAuthChallengeResponse {
        return .init(
            nonce: RandomBytesGenerator().generateBytes(length: 16).hexString,
            sessionId: "098acd0987ba0af0787ff8abc90dcb12=098acd0987ba0af0787ff8abc90dcb12=="
        )
    }

    func getCustomerWalletAuthorizationChallenge(
        customerWalletAddress: String,
        customerWalletId: String
    ) async throws -> VisaAuthChallengeResponse {
        return .init(
            nonce: RandomBytesGenerator().generateBytes(length: 16).hexString,
            sessionId: "098acd0987ba0af0787ff8abc90dcb12=098acd0987ba0af0787ff8abc90dcb12=="
        )
    }

    func getAccessTokensForCardAuth(signedChallenge: String, salt: String, sessionId: String) async throws -> VisaAuthorizationTokens {
        return authorizationTokens
    }

    func getAccessTokensForWalletAuth(signedChallenge: String, salt: String, sessionId: String) async throws -> VisaAuthorizationTokens {
        guard VisaMocksManager.instance.isWalletAuthorizationTokenEnabled else {
            throw VisaAPIError(code: 110206, name: "VisaMockManager", message: "Should use card authorization")
        }

        return authorizationTokens
    }

    func getAccessTokensForCustomerWalletAuth(sessionId: String, signedChallenge: String, messageFormat: String) async throws -> VisaAuthorizationTokens {
        return authorizationTokens
    }

    func refreshAccessToken(refreshToken: String, authorizationType authType: VisaAuthorizationType) async throws -> VisaAuthorizationTokens {
        return try await getAccessTokensForCardAuth(signedChallenge: "", salt: "", sessionId: "")
    }

    func exchangeTokens(accessToken: String, refreshToken: String, authorizationType: VisaAuthorizationType) async throws -> VisaAuthorizationTokens {
        return authorizationTokens
    }
}

// MARK: - VisaCardActivationStatusService

struct CardActivationStatusServiceMock: VisaCardActivationStatusService {
    func getCardActivationStatus(cardId: String, cardPublicKey: String) async throws -> VisaCardActivationStatus {
        return .init(
            activationRemoteState: VisaMocksManager.instance.activationRemoteState,
            activationOrder: VisaMocksManager.instance.activationOrder
        )
    }
}

struct CardActivationTaskOrderProviderMock: CardActivationOrderProvider {
    func provideActivationOrderForSign(walletAddress: String, activationInput: VisaCardActivationInput) async throws -> VisaCardAcceptanceOrderInfo {
        let generator = RandomBytesGenerator()
        return VisaCardAcceptanceOrderInfo(
            activationOrder: VisaMocksManager.instance.activationOrder,
            hashToSignByWallet: generator.generateBytes(length: 32)
        )
    }
}

// MARK: - ProductActivationService

struct ProductActivationServiceMock: ProductActivationService {
    func getVisaCardDeployAcceptance(activationOrderId: String, customerWalletAddress: String, cardWalletAddress: String) async throws -> String {
        let generator = RandomBytesGenerator()
        return generator.generateBytes(length: 32).hexString
    }

    func sendSignedVisaCardDeployAcceptance(activationOrderId: String, cardWalletAddress: String, signedAcceptance: String, rootOtp: String, rootOtpCounter: Int) async throws {
        VisaMocksManager.instance.changeActivationRemoteState(to: .customerWalletSignatureRequired)
    }

    func getCustomerWalletDeployAcceptance(activationOrderId: String, customerWalletAddress: String, cardWalletAddress: String) async throws -> String {
        let generator = RandomBytesGenerator()
        return generator.generateBytes(length: 32).hexString
    }

    func sendSignedCustomerWalletDeployAcceptance(activationOrderId: String, customerWalletAddress: String, deployAcceptanceSignature: String) async throws {
        VisaMocksManager.instance.changeActivationRemoteState(to: .paymentAccountDeploying)
    }

    func sendSelectedPINCodeToIssuer(activationOrderId: String, sessionKey: String, iv: String, encryptedPin: String) async throws {
        VisaMocksManager.instance.changeActivationRemoteState(to: .waitingForActivationFinishing)
    }
}

final class CustomerInfoManagementServiceMock: CustomerInfoManagementService {
    func cancelKYC() async throws -> TangemPayCancelKYCResponse {
        return .init()
    }

    func getPin(cardId: String, sessionId: String) async throws -> TangemPayGetPinResponse {
        .init(
            encryptedPin: "",
            iv: ""
        )
    }

    func loadCustomerInfo() async throws -> VisaCustomerInfoResponse {
        return .init(
            id: "89983505-cc0f-47d6-b428-eef3e158c5aa",
            state: .active,
            createdAt: Date(),
            productInstance: .init(
                id: "0550913f-b5ec-4e84-aada-4dcac86a3e4f",
                cardWalletAddress: "0xd971a808a08163b197e1e119cdba5d26ea3543bf",
                cardId: "5c5ad769-9b2d-4b16-952a-6f4e51833cba",
                cid: "FF05000000098425",
                status: .active,
                updatedAt: Date(),
                paymentAccountId: "5add5bde-04e7-4efd-9191-cb7f21956c00"
            ),
            paymentAccount: .init(
                id: "5add5bde-04e7-4efd-9191-cb7f21956c00",
                customerWalletAddress: "0xef08ea3531d219ede813fb521e6d89220198bcb1",
                address: "0xd7d2d8266e79d22be3680a062e19484140e248d1"
            ),
            kyc: .init(
                id: "",
                provider: "",
                status: .undefined,
                risk: .undefined,
                reviewAnswer: .undefined,
                createdAt: Date()
            ),
            card: nil,
            depositAddress: nil
        )
    }

    func loadKYCAccessToken() async throws -> VisaKYCAccessTokenResponse {
        VisaKYCAccessTokenResponse(token: "", locale: "")
    }

    func getBalance() async throws -> TangemPayBalance {
        .init(
            fiat: .init(
                currency: "",
                availableBalance: .zero,
                creditLimit: .zero,
                pendingCharges: .zero,
                postedCharges: .zero,
                balanceDue: .zero
            ),
            crypto: .init(
                id: "",
                chainId: .zero,
                depositAddress: "",
                tokenContractAddress: "",
                balance: .zero
            ),
            availableForWithdrawal: .init(
                amount: .zero,
                currency: ""
            )
        )
    }

    func getCardDetails(sessionId: String) async throws -> TangemPayCardDetailsResponse {
        TangemPayCardDetailsResponse(
            expirationMonth: "",
            expirationYear: "",
            pan: .init(secret: "", iv: ""),
            cvv: .init(secret: "", iv: ""),
            isPinSet: .init()
        )
    }

    func freeze(cardId: String) async throws -> TangemPayFreezeUnfreezeResponse {
        .init(orderId: "", status: .processing)
    }

    func unfreeze(cardId: String) async throws -> TangemPayFreezeUnfreezeResponse {
        .init(orderId: "", status: .processing)
    }

    func setPin(pin: String, sessionId: String, iv: String) async throws -> TangemPaySetPinResponse {
        .init(result: .success)
    }

    func getTransactionHistory(limit: Int, cursor: String?) async throws -> TangemPayTransactionHistoryResponse {
        TangemPayTransactionHistoryResponse(transactions: [])
    }

    func getWithdrawPreSignatureInfo(request: TangemPayWithdrawRequest) async throws -> TangemPayWithdrawPreSignature {
        .init(sender: "", hash: Data(), salt: Data())
    }

    func sendWithdrawTransaction(request: TangemPayWithdrawRequest, signature: TangemPayWithdrawSignature) async throws -> TangemPayWithdrawTransactionResult {
        .init(orderID: UUID().uuidString, host: "")
    }

    func getOrder(orderId: String) async throws -> TangemPayOrderResponse {
        TangemPayOrderResponse(
            id: "",
            customerId: "",
            type: "",
            status: .new,
            step: "",
            data: .init(
                type: "",
                specificationName: "",
                customerWalletAddress: "",
                embossName: nil,
                productInstanceId: nil,
                paymentAccountId: nil
            ),
            stepChangeCode: 0
        )
    }

    func placeOrder(customerWalletAddress: String) async throws -> TangemPayOrderResponse {
        TangemPayOrderResponse(
            id: "",
            customerId: "",
            type: "",
            status: .new,
            step: "",
            data: .init(
                type: "",
                specificationName: "",
                customerWalletAddress: "",
                embossName: nil,
                productInstanceId: nil,
                paymentAccountId: nil
            ),
            stepChangeCode: 0
        )
    }
}

private struct RandomBytesGenerator {
    func generateBytes(length: Int) -> Data {
        return Data((0 ..< length).map { _ -> UInt8 in
            UInt8(arc4random_uniform(255))
        })
    }
}

private extension VisaCardActivationRemoteState {
    static var allCases: [VisaCardActivationRemoteState] = [
        .cardWalletSignatureRequired,
        .customerWalletSignatureRequired,
        .paymentAccountDeploying,
        .waitingPinCode,
        .waitingForActivationFinishing,
        .activated,
        .blockedForActivation,
    ]
}
