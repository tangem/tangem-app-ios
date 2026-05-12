//
//  UserWalletIdSpoofingViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import UIKit
import Combine

// import TangemSdk
import TangemFoundation
import TangemAssets
import struct TangemUIUtils.AlertBinder

final class UserWalletIdSpoofingViewModel: ObservableObject {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    // MARK: - State

    @Published private(set) var walletRows: [WalletRow] = []
    @Published private(set) var spoofMappingRows: [SpoofMappingRow] = []
    @Published var alert: AlertBinder?

    // MARK: - Add-mapping sheet state

    @Published var isAddSheetPresented: Bool = false
    @Published var draftOriginalHex: String = ""
    @Published var draftSpoofedHex: String = ""

    // MARK: - Dependencies

    private let featureStorage = FeatureStorage.instance

    // MARK: - Init

    init() {
        refresh()
    }

    // MARK: - Read

    func refresh() {
        let map = featureStorage.userWalletIdSpoofMap

        walletRows = userWalletRepository
            .models
            .map { wallet in
                let currentId = wallet.userWalletId.stringValue
                let originalId = map.first(where: { $0.value.hexString.uppercased() == currentId.uppercased() })?.key
                return WalletRow(
                    id: wallet.userWalletId,
                    name: wallet.name,
                    currentId: currentId,
                    originalId: originalId
                )
            }

        spoofMappingRows = map
            .map { SpoofMappingRow(originalHex: $0.key, spoofedHex: $0.value.hexString) }
            .sorted { $0.originalHex < $1.originalHex }
    }

    // MARK: - Add-mapping flow

    func presentAddMapping(prefillOriginal: String?) {
        draftOriginalHex = prefillOriginal ?? ""
        draftSpoofedHex = ""
        isAddSheetPresented = true
    }

    func saveDraftMapping() {
        let originalKey = draftOriginalHex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let spoofedKey = draftSpoofedHex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        guard originalKey.isNotEmpty, spoofedKey.isNotEmpty else {
            presentAlert(title: "Invalid input", message: "Both fields are required.")
            return
        }

        let spoofedData = Data(hexString: spoofedKey)

        guard spoofedData.isNotEmpty else {
            presentAlert(title: "Invalid hex", message: "The Spoofed value couldn't be parsed as a hex string.")
            return
        }

        var current = featureStorage.userWalletIdSpoofMap
        current[originalKey] = spoofedData
        featureStorage.userWalletIdSpoofMap = current

        isAddSheetPresented = false
        refresh()
    }

    func cancelDraftMapping() {
        isAddSheetPresented = false
    }

    // MARK: - Mutations

    func deleteMapping(originalHex: String) {
        var current = featureStorage.userWalletIdSpoofMap
        current.removeValue(forKey: originalHex)
        featureStorage.userWalletIdSpoofMap = current
        refresh()
    }

    func clearAllMappings() {
        featureStorage.userWalletIdSpoofMap.removeAll()
        refresh()
    }

    // MARK: - Clipboard

    func copyToClipboard(_ value: String) {
        UIPasteboard.general.string = value
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    // MARK: - Helpers

    private func presentAlert(title: String, message: String) {
        alert = AlertBuilder.makeAlertWithDefaultPrimaryButton(
            title: title,
            message: message,
            buttonText: AlertBuilder.okButtonTitle
        )
    }
}

// MARK: - Row models

extension UserWalletIdSpoofingViewModel {
    struct WalletRow: Identifiable {
        let id: UserWalletId
        let name: String
        let currentId: String
        let originalId: String?
    }

    struct SpoofMappingRow: Identifiable {
        var id: String { originalHex }
        let originalHex: String
        let spoofedHex: String
    }
}
