//
//  ActivatedVisaCardDummyManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemVisa

/// This class should be used for activated card to go through Biometrics and Notification setup
class ActivatedVisaCardDummyManager: VisaActivationManager {
    var targetApproveAddress: String?

    var isAccessCodeSet: Bool { true }
    var isContinuingActivation: Bool { true }
    var activationLocalState: TangemVisa.VisaCardActivationLocalState {
        .activated(authTokens: .init(accessToken: "", refreshToken: "", authorizationType: .cardWallet))
    }

    var activationRemoteState: VisaCardActivationRemoteState {
        .activated
    }

    func saveAccessCode(accessCode: String) throws(TangemVisa.VisaAccessCodeValidationError) {}

    func startActivation() async throws(TangemVisa.VisaActivationError) -> CardActivationResponse {
        throw .alreadyActivated
    }

    func validateAccessCode(accessCode: String) throws(TangemVisa.VisaAccessCodeValidationError) {}

    func resetAccessCode() {}

    func setupRefreshTokenSaver(_ refreshTokenSaver: any TangemVisa.VisaRefreshTokenSaver) {}

    func refreshActivationRemoteState() async throws(TangemVisa.VisaActivationError) -> TangemVisa.VisaCardActivationRemoteState {
        .activated
    }

    func getCustomerWalletApproveHash() async throws(TangemVisa.VisaActivationError) -> Data {
        return Data()
    }

    func sendSignedCustomerWalletApprove(_ signedData: Data) async throws(TangemVisa.VisaActivationError) {}

    func setPINCode(_ pinCode: String) async throws(TangemVisa.VisaActivationError) {}
}
