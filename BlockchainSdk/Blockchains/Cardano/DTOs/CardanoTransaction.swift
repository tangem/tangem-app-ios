//
//  CardanoTransaction.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftCBOR

struct CardanoTransaction {
    let body: CardanoTransactionBody
    let witnessSet: Data?
    let isValid: Bool
    let auxiliaryData: Data?
}

struct CardanoTransactionBody {
    let inputs: [Input]
    let outputs: [Output]
    let fee: Decimal
    let auxiliaryScripts: String?
    let certificates: [Certificate]
    let collateralInputs: [String]?
    let currentTreasuryValue: String?
    let era: String?
    let governanceActions: [String]?
    let metadata: String?
    let mint: String?
    let redeemers: [String]?
    let referenceInputs: [String]?
    let requiredSigners: String?
    let returnCollateral: String?
    let totalCollateral: String?
    let updateProposal: String?
    let voters: [String: String]?
    let withdrawals: [RewardAddress: UInt64]?
    let witnesses: [String]?

    init(
        inputs: [Input],
        outputs: [Output],
        fee: Decimal,
        auxiliaryScripts: String? = nil,
        certificates: [Certificate],
        collateralInputs: [String]? = nil,
        currentTreasuryValue: String? = nil,
        era: String? = nil,
        governanceActions: [String]? = nil,
        metadata: String? = nil,
        mint: String? = nil,
        redeemers: [String]? = nil,
        referenceInputs: [String]? = nil,
        requiredSigners: String? = nil,
        returnCollateral: String? = nil,
        totalCollateral: String? = nil,
        updateProposal: String? = nil,
        voters: [String: String]? = nil,
        withdrawals: [RewardAddress: UInt64]? = nil,
        witnesses: [String]? = nil
    ) {
        self.inputs = inputs
        self.outputs = outputs
        self.fee = fee
        self.auxiliaryScripts = auxiliaryScripts
        self.certificates = certificates
        self.collateralInputs = collateralInputs
        self.currentTreasuryValue = currentTreasuryValue
        self.era = era
        self.governanceActions = governanceActions
        self.metadata = metadata
        self.mint = mint
        self.redeemers = redeemers
        self.referenceInputs = referenceInputs
        self.requiredSigners = requiredSigners
        self.returnCollateral = returnCollateral
        self.totalCollateral = totalCollateral
        self.updateProposal = updateProposal
        self.voters = voters
        self.withdrawals = withdrawals
        self.witnesses = witnesses
    }
}

extension CardanoTransactionBody {
    struct Input {
        let transactionID: String
        let index: UInt64
    }

    struct Output {
        let address: String
        let amount: UInt64
    }

    struct Credential: Hashable {
        let keyHash: Data
    }

    struct RewardAddress: Hashable {
        let network: UInt8?
        let credential: Credential?
    }

    struct StakeDelegation {
        let credential: Credential
        let poolKeyHash: Data
    }

    struct StakeRegistrationLegacy {
        let credential: Credential
    }

    struct StakeDeregistrationLegacy {
        let credential: Credential
    }

    struct StakeDeregistrationConway {
        let credential: Credential
        let coin: UInt64
    }

    enum Certificate {
        case stakeRegistrationLegacy(StakeRegistrationLegacy)
        case stakeDeregistrationLegacy(StakeDeregistrationLegacy)
        case stakeDelegation(StakeDelegation)
        case poolRegistration
        case poolRetirement
        case genesisKeyDelegation
        case moveInstantaneousRewardsCert
        case stakeRegistrationConway
        case stakeDeregistrationConway(StakeDeregistrationConway)
        case voteDelegation
        case stakeAndVoteDelegation
        case stakeRegistrationAndDelegation
        case voteRegistrationAndDelegation
        case stakeVoteRegistrationAndDelegation
        case committeeHotAuth
        case committeeColdResign
        case dRepRegistration
        case dRepDeregistration
        case dRepUpdate

        enum Index: UInt64, RawRepresentable {
            case stakeRegistrationLegacy = 0
            case stakeDeregistrationLegacy
            case stakeDelegation
            case poolRegistration
            case poolRetirement
            case genesisKeyDelegation
            case moveInstantaneousRewardsCert
            case stakeRegistrationConway
            case stakeDeregistrationConway
            case voteDelegation
            case stakeAndVoteDelegation
            case stakeRegistrationAndDelegation
            case voteRegistrationAndDelegation
            case stakeVoteRegistrationAndDelegation
            case committeeHotAuth
            case committeeColdResign
            case dRepRegistration
            case dRepDeregistration
            case dRepUpdate
        }
    }
}

extension CardanoTransactionBody {
    init?(cbor: CBOR) {
        guard case .array(let byteString) = cbor else {
            return nil
        }

        guard case .map(let map) = byteString.first else {
            return nil
        }

        var inputs: [Input]?
        var outputs: [Output]?
        var fee: Decimal?
        var certificates: [Certificate]?
        var withdrawals: [RewardAddress: UInt64]?

        for (key, element) in map {
            guard case .unsignedInt(let uInt) = key else {
                continue
            }

            switch uInt {
            case 0: inputs = Self.parseInputs(element)
            case 1: outputs = Self.parseOutputs(element)
            case 2: fee = Self.parseFee(element)
            case 4: certificates = Self.parseCerts(element)
            case 5: withdrawals = Self.parseWithdrawals(element)
            default: continue
            }
        }

        guard let inputs, let outputs, let fee, let certificates else { return nil }

        self.init(
            inputs: inputs,
            outputs: outputs,
            fee: fee,
            certificates: certificates,
            withdrawals: withdrawals
        )
    }

    private static func parseInputs(_ cbor: CBOR) -> [CardanoTransactionBody.Input]? {
        guard case .tagged(let tag, let cbor) = cbor,
              tag.rawValue == Constants.stakingTag,
              case .array(let inputs) = cbor else {
            return nil
        }

        return inputs.compactMap { inputCBOR in
            CardanoTransactionBody.Input(cbor: inputCBOR)
        }
    }

    private static func parseOutputs(_ cbor: CBOR) -> [CardanoTransactionBody.Output]? {
        guard case .array(let outputs) = cbor else {
            return nil
        }

        return outputs.compactMap { outputCBOR in
            CardanoTransactionBody.Output(cbor: outputCBOR)
        }
    }

    private static func parseFee(_ cbor: CBOR) -> Decimal? {
        if case .unsignedInt(let uInt64) = cbor {
            return Decimal(uInt64)
        }
        return nil
    }

    private static func parseCerts(_ cbor: CBOR) -> [CardanoTransactionBody.Certificate]? {
        guard case .tagged(let tag, let cbor) = cbor,
              tag.rawValue == Constants.stakingTag,
              case .array(let certs) = cbor else {
            return nil
        }

        return certs.compactMap { certCBOR -> CardanoTransactionBody.Certificate? in
            guard case .array(let certInfo) = certCBOR else {
                return nil
            }

            guard case .unsignedInt(let index) = certInfo[0] else { return nil }

            switch index {
            case CardanoTransactionBody.Certificate.Index.stakeRegistrationLegacy.rawValue:
                return CardanoTransactionBody.StakeRegistrationLegacy(cbor: certCBOR).flatMap {
                    .stakeRegistrationLegacy($0)
                }
            case CardanoTransactionBody.Certificate.Index.stakeDelegation.rawValue:
                return CardanoTransactionBody.StakeDelegation(cbor: certCBOR).flatMap { .stakeDelegation($0) }
            case CardanoTransactionBody.Certificate.Index.stakeDeregistrationLegacy.rawValue:
                return CardanoTransactionBody.StakeDeregistrationLegacy(cbor: certCBOR).flatMap {
                    .stakeDeregistrationLegacy($0)
                }
            case CardanoTransactionBody.Certificate.Index.stakeDeregistrationConway.rawValue:
                return CardanoTransactionBody.StakeDeregistrationConway(cbor: certCBOR).flatMap {
                    .stakeDeregistrationConway($0)
                }
            default:
                return nil // not implemented
            }
        }
    }

    private static func parseWithdrawals(_ cbor: CBOR) -> [RewardAddress: UInt64]? {
        guard case .map(let dictionary) = cbor else {
            return nil
        }

        return dictionary.reduce(into: [:]) { partialResult, pair in
            guard let address = RewardAddress(cbor: pair.key),
                  case .unsignedInt(let uInt64) = pair.value else {
                return
            }
            partialResult[address] = uInt64
        }
    }
}

extension CardanoTransactionBody.Input {
    init?(cbor: CBOR) {
        guard case .array(let inputInfo) = cbor, inputInfo.count == 2 else {
            return nil
        }

        guard case .byteString(let bytes) = inputInfo[0],
              bytes.count == 32 else {
            return nil
        }

        guard case .unsignedInt(let uInt64) = inputInfo[1] else {
            return nil
        }

        transactionID = Data(bytes).hexString
        index = uInt64
    }
}

extension CardanoTransactionBody.Output {
    init?(cbor: CBOR) {
        guard case .array(let outputInfo) = cbor,
              outputInfo.count == 2 else {
            return nil
        }

        guard case .byteString(let bytes) = outputInfo[0] else { return nil }

        guard case .unsignedInt(let uInt64) = outputInfo[1] else { return nil }

        address = Data(bytes).hex
        amount = uInt64
    }
}

extension CardanoTransactionBody.RewardAddress {
    /// address parsing is really complex, skip since it is not used at the moment
    init?(cbor: CBOR) {
        guard case .byteString = cbor else { return nil }

        network = nil
        credential = nil
    }
}

extension CardanoTransactionBody.StakeDelegation {
    init?(cbor: CBOR) {
        guard case .array(let certInfo) = cbor,
              certInfo.count == 3 /* cert_index, stake_credential, pool_keyhash */ else {
            return nil
        }

        guard case .array(let credentials) = certInfo[1],
              credentials.count == 2 else { // credential type, byte array
            return nil
        }

        guard case .unsignedInt(let credentialType) = credentials[0],
              credentialType == 0 else { // 0 - key hash, 1 - script hash
            return nil
        }

        guard case .byteString(let keyHashArray) = credentials[1],
              keyHashArray.count == 28 else { // 28 bytes ed key
            return nil
        }

        guard case .byteString(let poolKeyHashArray) = certInfo[2] else {
            return nil
        }

        credential = CardanoTransactionBody.Credential(keyHash: Data(keyHashArray))
        poolKeyHash = Data(poolKeyHashArray)
    }
}

extension CardanoTransactionBody.StakeRegistrationLegacy {
    init?(cbor: CBOR) {
        guard case .array(let certInfo) = cbor,
              certInfo.count == 2 /* cert_index, stake_credential */ else {
            return nil
        }

        guard case .array(let credentials) = certInfo[1],
              credentials.count == 2 else { // credential type, byte array
            return nil
        }

        guard case .unsignedInt(let credentialType) = credentials[0],
              credentialType == 0 else { // 0 - key hash, 1 - script hash
            return nil
        }

        guard case .byteString(let keyHashArray) = credentials[1],
              keyHashArray.count == 28 else { // 28 bytes ed key
            return nil
        }

        credential = CardanoTransactionBody.Credential(keyHash: Data(keyHashArray))
    }
}

extension CardanoTransactionBody.StakeDeregistrationConway {
    init?(cbor: CBOR) {
        guard case .array(let certInfo) = cbor,
              certInfo.count == 2 /* cert_index, stake_credential, coin */ else {
            return nil
        }

        guard case .array(let credentials) = certInfo[1],
              credentials.count == 2 else { // credential type, byte array
            return nil
        }

        guard case .unsignedInt(let credentialType) = credentials[0],
              credentialType == 0 else { // 0 - key hash, 1 - script hash
            return nil
        }

        guard case .byteString(let keyHashArray) = credentials[1],
              keyHashArray.count == 28 else { // 28 bytes ed key
            return nil
        }

        guard case .unsignedInt(let coinAmount) = credentials[2] else {
            return nil
        }

        credential = CardanoTransactionBody.Credential(keyHash: Data(keyHashArray))
        coin = coinAmount
    }
}

extension CardanoTransactionBody.StakeDeregistrationLegacy {
    init?(cbor: CBOR) {
        guard case .array(let certInfo) = cbor,
              certInfo.count == 2 /* cert_index, stake_credential */ else {
            return nil
        }

        guard case .array(let credentials) = certInfo[1],
              credentials.count == 2 else { // credential type, byte array
            return nil
        }

        guard case .unsignedInt(let credentialType) = credentials[0],
              credentialType == 0 else { // 0 - key hash, 1 - script hash
            return nil
        }

        guard case .byteString(let keyHashArray) = credentials[1],
              keyHashArray.count == 28 else { // 28 bytes ed key
            return nil
        }

        credential = CardanoTransactionBody.Credential(keyHash: Data(keyHashArray))
    }
}

extension CardanoTransactionBody {
    enum Constants {
        static let stakingTag: UInt64 = 258
    }
}
