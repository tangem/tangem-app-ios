//
//  TangemPayEnrollmentStateFetcher.swift
//  TangemPay
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

public struct TangemPayEnrollmentStateFetcher {
    public let customerWalletId: String
    public let customerWalletAddressAndAuthorizationTokensProvider: TangemPayCustomerWalletAddressAndAuthorizationTokensProvider
    public let paeraCustomerFlagRepository: TangemPayPaeraCustomerFlagRepository
    public let availabilityService: TangemPayAvailabilityService
    public let customerService: TangemPayCustomerService

    public init(
        customerWalletId: String,
        customerWalletAddressAndAuthorizationTokensProvider: TangemPayCustomerWalletAddressAndAuthorizationTokensProvider,
        paeraCustomerFlagRepository: TangemPayPaeraCustomerFlagRepository,
        availabilityService: TangemPayAvailabilityService,
        customerService: TangemPayCustomerService
    ) {
        self.customerWalletId = customerWalletId
        self.customerWalletAddressAndAuthorizationTokensProvider = customerWalletAddressAndAuthorizationTokensProvider
        self.paeraCustomerFlagRepository = paeraCustomerFlagRepository
        self.availabilityService = availabilityService
        self.customerService = customerService
    }

    public func getEnrollmentState() async throws(TangemPayAPIServiceError) -> TangemPayEnrollmentState {
        guard let (customerWalletAddress, _) = customerWalletAddressAndAuthorizationTokensProvider.get(customerWalletId: customerWalletId) else {
            throw .unauthorized
        }

        guard await isPaeraCustomer() else {
            return .notEnrolled
        }

        let customerInfo = try await customerService.loadCustomerInfo()

        if let productInstance = customerInfo.productInstance {
            switch productInstance.status {
            case .active, .blocked:
                return .enrolled(customerInfo: customerInfo, productInstance: productInstance)

            default:
                break
            }
        }

        guard customerInfo.kyc?.status == .approved else {
            return .kyc
        }

        return .issuingCard(customerWalletAddress: customerWalletAddress)
    }

    private func isPaeraCustomer() async -> Bool {
        if paeraCustomerFlagRepository.isPaeraCustomer(customerWalletId: customerWalletId) {
            return true
        }

        guard let isPaeraCustomerResponse = try? await availabilityService.isPaeraCustomer(customerWalletId: customerWalletId) else {
            return false
        }

        paeraCustomerFlagRepository.setIsPaeraCustomer(for: customerWalletId)
        paeraCustomerFlagRepository.setIsKYCHidden(!isPaeraCustomerResponse.isTangemPayEnabled, for: customerWalletId)

        return true
    }
}
