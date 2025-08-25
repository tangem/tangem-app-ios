//
//  SignUtilTests.swift
//  TangemHotSdk
//
//  Created by [REDACTED_AUTHOR]
//

import Testing
import Foundation
@testable import TangemHotSdk
@testable import TangemSdk

let edHexToSign = "BFF1F484E7CD3B3AEB4843ACCFDF5FDAEEFA6F2073FE0B366C092CAA0212040265BCB0D64087DFFAAD8A0848AE90477B229EA81B51CAE3C705FAC19EEF2A8D72"

struct SignUtilTests {
    @Test
    func signProducesCorrectEdCardanoSignatures() throws {
        let signaturesDefaultDerivation = try SignUtil.sign(
            entropy: entropy,
            hashes: [Data(hexString: edHexToSign)],
            curve: .ed25519,
            derivationPath: "m/1852'/1815'/0'/0/0"
        )

        let expected1 = Data(hexString: "12838C65B5431AA5E4AF29FF49FFE46B0C5409B67DE606D83521CAD40349EA165DDE1E2832408B4A1441C8963BCE80CD5CE610B7A0AC979934CA5A12EF523D01")

        #expect(signaturesDefaultDerivation.count == 1)
        #expect(signaturesDefaultDerivation.first == .some(expected1))

        let signaturesStakingDerivation = try SignUtil.sign(
            entropy: entropy,
            hashes: [Data(hexString: edHexToSign)],
            curve: .ed25519,
            derivationPath: "m/1852'/1815'/0'/2/0"
        )

        let expected2 = Data(hexString: "2892D2AEA56338F601ED588410CB02695B8D702D5B516FB778316113596225FA0C46D46790423C96C46D3EAF7DF3FD232CECD27F8D4C056817581FDFB1A81D0C")

        #expect(signaturesStakingDerivation.count == 1)
        #expect(signaturesStakingDerivation.first == .some(expected2))
    }

    @Test
    func signProducesCorrectEdSignatures() throws {
        let signatures = try SignUtil.sign(
            entropy: entropy,
            hashes: [Data(hexString: edHexToSign)],
            curve: .ed25519_slip0010,
            derivationPath: "m/44'/354'/0'/0'/0'"
        )

        let expected = Data(hexString: "876AE4FF6A409AC063D509AD180D8B44BC85C31063257F38A347859DDE00C0F1C9BE0B836C52C2C7298ADFEC99E31E3A547FE78C706D526D4CC3814D2B741D03")

        #expect(signatures.count == 1)
        #expect(signatures.first == .some(expected))
    }

    @Test
    func signProducesCorrectSecp256k1Signatures() throws {
        let hash = Data(hexString: "BFF1F484E7CD3B3AEB4843ACCFDF5FDAEEFA6F2073FE0B366C092CAA02120402")

        let signatures = try SignUtil.sign(
            entropy: entropy,
            hashes: [hash],
            curve: .secp256k1,
            derivationPath: "m/84'/0'/0'/0/0"
        )

        let signatureData = try #require(signatures.first)

        let signature = try Secp256k1Signature(with: signatureData)

        let result = try signature.verify(
            with: Data(
                hexString: "02616104143281B4679AFEB669392B073D63564606F431D13DF3EBEDE75D269509"
            ),
            hash: hash
        )

        #expect(result)
    }
}
