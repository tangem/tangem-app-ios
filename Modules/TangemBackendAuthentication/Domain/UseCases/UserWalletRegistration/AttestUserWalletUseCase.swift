//
//  AttestUserWalletUseCase.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public import TangemFoundation

typealias AttestUserWallet = @Sendable (
    _ id: UserWalletId,
    _ nonce: UserWalletRegistrationNonce,
    _ signer: any UserWalletRegistrationSigner
) async throws(AttestUserWalletError) -> UserWalletRegistrationRequest?

public struct AttestUserWalletUseCase: Sendable {
    private let registrationStatusRepository: any UserWalletRegistrationStatusRepository
    private let deviceMetadataProvider: @Sendable () -> DeviceMetadata

    init(
        registrationStatusRepository: some UserWalletRegistrationStatusRepository,
        deviceMetadataProvider: @escaping @Sendable @autoclosure () -> DeviceMetadata
    ) {
        self.registrationStatusRepository = registrationStatusRepository
        self.deviceMetadataProvider = deviceMetadataProvider
    }

    public func callAsFunction(
        id: UserWalletId,
        nonce: UserWalletRegistrationNonce,
        signer: some UserWalletRegistrationSigner
    ) async throws(AttestUserWalletError) -> UserWalletRegistrationRequest? {
        // [REDACTED_TODO_COMMENT]
        let userWalletIsAlreadyRegistered = await registrationStatusRepository.retrieve(id: id)

        guard !userWalletIsAlreadyRegistered else {
            return nil
        }

        let walletAttestation = try await generateUserWalletAttestation(signer: signer, nonce: nonce)

        return UserWalletRegistrationRequest(
            id: id,
            walletAttestation: walletAttestation,
            decryptedNonce: nonce.value,
            appAttestationToken: nonce.appAttestationToken,
            metadata: deviceMetadataProvider()
        )
    }

    private func generateUserWalletAttestation(
        signer: some UserWalletRegistrationSigner,
        nonce: UserWalletRegistrationNonce
    ) async throws(AttestUserWalletError) -> UserWalletAttestation {
        do {
            return try await signer.attest(decryptedNonceBytes: nonce.bytesToSign)
        } catch {
            throw AttestUserWalletError.signerFailure(error)
        }
    }
}
