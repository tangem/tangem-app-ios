//
//  CollectiblesProgramRejection.swift
//  TangemCollectibles
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Codes from 6000 up are the ones the vault program declares. The lower ones come from the layer that
/// checks an instruction's accounts before the program's own code runs.
public enum CollectiblesProgramRejection: UInt32, Error {
    /// A build that still spells the spin `open_pack` reaches the chain and fails here.
    case instructionFallbackNotFound = 101

    /// For the singleton config it means the 174-byte image outlived its `migrate_config`, and until that
    /// runs no vault can spend.
    case accountDidNotDeserialize = 3003

    /// A wallet address was passed where a token account belongs.
    case accountOwnedByWrongProgram = 3007

    case invalidProgramId = 3008

    /// The vault's USDC account before anything created it.
    case accountNotInitialized = 3012

    case paused = 6000
    case zeroAmount = 6001
    case invalidMemo = 6002
    case invalidFeeBps = 6003
    case invalidCaps = 6004
    case exceedsPerSpinCap = 6005
    case exceedsDailyCap = 6006
    case mathOverflow = 6007
    case notAnNft = 6008
    case buybackDelegationDisabled = 6009
    case buybackSlotOccupied = 6010
    case noLiveBuyback = 6011
    case wrongBuybackToken = 6012
    case buybackStillActive = 6013
    case vaultNotClean = 6014
    case tokenAccountNotEmpty = 6015
    case delegateStillSet = 6016
    case insufficientSol = 6017

    /// For a spin, a session key the vault no longer names.
    case unauthorized = 6018

    case cannotSweepUsdc = 6019
    case excessLamports = 6020
    case unsupportedMint = 6021
    case feeBelowMinimum = 6022
    case feeAboveMaximum = 6023
    case invalidConfigAccount = 6024
}
