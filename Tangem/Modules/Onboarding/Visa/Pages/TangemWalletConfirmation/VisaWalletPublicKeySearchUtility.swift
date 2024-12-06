struct VisaWalletPublicKeySearchUtility {
    private let visaUtilities = VisaUtilities()

    func findPublicKey(targetAddress: String, derivationPath: DerivationPath?, on card: Card) throws (SearchError) -> Data {
        if let derivationPath {
            return try findKeyWithDerivation(targetAddress: targetAddress, derivationPath: derivationPath, on: card)
        } else {
            return try findKeyWithoutDerivation(targetAddress: targetAddress, on: card)
        }
    }

    func validatePublicKey(targetAddress: String, publicKey: Data) throws (SearchError) {
        let addressService = visaUtilities.addressService

        let createdAddress: Address
        do {
            createdAddress = try addressService.makeAddress(
                for: .init(seedKey: publicKey, derivationType: .none),
                with: .default
            )
        } catch {
            throw .failedToGenerateAddress(error)
        }

        try validateCreatedAddress(targetAddress: targetAddress, createdAddress: createdAddress)
    }

    func validateExtendedPublicKey(
        targetAddress: String,
        extendedPublicKey: ExtendedPublicKey,
        derivationPath: DerivationPath
    ) throws (SearchError) {
        let addressService = visaUtilities.addressService

        let createdAddress: Address
        do {
            createdAddress = try addressService.makeAddress(
                for: .init(
                    seedKey: extendedPublicKey.publicKey,
                    derivationType: .plain(.init(
                        path: derivationPath,
                        extendedPublicKey: extendedPublicKey
                    ))
                ),
                with: .default
            )
        } catch {
            throw .failedToGenerateAddress(error)
        }

        try validateCreatedAddress(targetAddress: targetAddress, createdAddress: createdAddress)
    }

    private func findKeyWithoutDerivation(targetAddress: String, on card: Card) throws (SearchError) -> Data {
        guard let wallet = card.wallets.first(where: { $0.curve == visaUtilities.visaBlockchain.curve }) else {
            throw SearchError.missingWalletOnTargetCurve
        }

        try validatePublicKey(targetAddress: targetAddress, publicKey: wallet.publicKey)

        return wallet.publicKey
    }

    private func findKeyWithDerivation(targetAddress: String, derivationPath: DerivationPath, on card: Card) throws (SearchError) -> Data {
        guard let wallets = card.wallets.first(where: { $0.curve == visaUtilities.visaBlockchain.curve }) else {
            throw SearchError.missingWalletOnTargetCurve
        }

        guard let targetWallet = wallets.derivedKeys.keys[derivationPath] else {
            throw SearchError.missingDerivedKeys
        }

        try validateExtendedPublicKey(targetAddress: targetAddress, extendedPublicKey: targetWallet, derivationPath: derivationPath)

        return targetWallet.publicKey
    }

    private func validateCreatedAddress(targetAddress: String, createdAddress: any Address) throws (SearchError) {
        guard createdAddress.value == targetAddress else {
            throw SearchError.addressesNotMatch
        }
    }
}
