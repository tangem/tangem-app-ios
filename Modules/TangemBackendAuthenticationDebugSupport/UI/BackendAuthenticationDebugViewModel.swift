//
//  BackendAuthenticationDebugViewModel.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
public import Combine
import SwiftUI
import UIKit
import TangemAssets
import TangemBackendAuthentication
public import TangemFoundation
import struct TangemLogger.Logger
import TangemUI
import struct TangemUIUtils.AlertBinder

@MainActor
public final class BackendAuthenticationDebugViewModel: ObservableObject {
    @Published private(set) var infoRows: [ValueRow] = []
    @Published private(set) var registrationRow: ValueRow?
    @Published private(set) var registeredWalletRows: [UserWalletInfo] = []
    @Published private(set) var sessionRows: [ValueRow] = []
    @Published private(set) var runningAction: Action?
    @Published var alert: AlertBinder?

    var accessTokenExpiration: Date {
        get { _accessTokenExpiration ?? .now }
        set { _accessTokenExpiration = newValue }
    }

    @Published private var _accessTokenExpiration: Date?

    private let environmentName: String
    private let baseURL: URL
    private let userWalletInfos: [UserWalletInfo]
    private let debugService: BackendAuthenticationDebugService
    private let registerDevice: RegisterDeviceUseCase
    private let unregisterUserWallet: UnregisterUserWalletUseCase
    private let retrieveUserWalletRegistrationStatus: RetrieveUserWalletRegistrationStatusUseCase
    private let logger: Logger

    private static let expirationDateFormatter = DateFormatter(dateFormat: "dd.MM.yyyy HH:mm")

    private static let remainingTimeFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day, .hour, .minute]
        formatter.unitsStyle = .abbreviated
        formatter.maximumUnitCount = 2
        return formatter
    }()

    init(
        environmentName: String,
        baseURL: URL,
        userWalletInfos: [UserWalletInfo],
        debugService: BackendAuthenticationDebugService,
        registerDevice: RegisterDeviceUseCase,
        unregisterUserWallet: UnregisterUserWalletUseCase,
        retrieveUserWalletRegistrationStatus: RetrieveUserWalletRegistrationStatusUseCase,
        logger: Logger
    ) {
        self.environmentName = environmentName
        self.baseURL = baseURL
        self.userWalletInfos = userWalletInfos
        self.debugService = debugService
        self.registerDevice = registerDevice
        self.unregisterUserWallet = unregisterUserWallet
        self.retrieveUserWalletRegistrationStatus = retrieveUserWalletRegistrationStatus
        self.logger = logger

        runTask(in: self) { @MainActor viewModel in
            await viewModel.reload()
        }
    }

    func reload() async {
        let devicePublicKeyRow = await makeDevicePublicKeyRow()

        infoRows = [
            ValueRow(title: "Environment", value: .text(environmentDescription), subtitle: nil, copyValue: nil),
            devicePublicKeyRow,
        ]
        registrationRow = ValueRow(
            title: "Registered",
            value: .flag(debugService.isDeviceRegistered),
            subtitle: nil,
            copyValue: nil
        )
        registeredWalletRows = await makeRegisteredWalletRows()
        sessionRows = await makeSessionRows()
        _accessTokenExpiration = nil
    }

    func perform(_ action: Action) {
        guard runningAction == nil else {
            return
        }

        runningAction = action

        runTask(in: self) { @MainActor viewModel in
            do {
                let outcome = try await viewModel.execute(action)
                Self.present(outcome, of: action)
            } catch {
                viewModel.logger.error("Debug action '\(action.title)' failed", error: error)
                viewModel.alert = AlertBinder(title: action.title, message: String(describing: error))
            }

            await viewModel.reload()
            viewModel.runningAction = nil
        }
    }

    func copy(_ row: ValueRow) {
        guard let copyValue = row.copyValue else {
            return
        }

        UIPasteboard.general.string = copyValue
        Self.presentSuccessSnackbar(title: "Copied \(row.title)")
    }

    private func execute(_ action: Action) async throws -> ActionOutcome {
        switch action {
        case .registerDevice:
            let sessionTokens = try await registerDevice()

            return sessionTokens == nil ? .deviceAlreadyRegistered : .completed

        case .resetDeviceRegistration:
            try await debugService.resetDeviceRegistration()

            return .completed

        case .unregisterUserWallet(let id):
            try await unregisterUserWallet(id: id, shouldEraseSocialLoginData: false)

            return .completed

        case .forceRefresh:
            try await debugService.renewSessionTokens()

            return .completed

        case .corruptAccessToken:
            let sessionTokens = try await debugService.corruptAccessToken()

            return sessionTokens == nil ? .noSessionTokens : .completed

        case .expireAccessToken:
            let sessionTokens = try await debugService.expireAccessToken()

            return sessionTokens == nil ? .noSessionTokens : .completed

        case .setAccessTokenExpiration:
            let sessionTokens = try await debugService.setAccessTokenExpiration(to: accessTokenExpiration)

            return sessionTokens == nil ? .noSessionTokens : .completed

        case .clearSessionTokens:
            try await debugService.clearSessionTokens()

            return .completed
        }
    }

    private static func present(_ outcome: ActionOutcome, of action: Action) {
        switch outcome {
        case .completed:
            presentSuccessSnackbar(title: action.title)
        case .deviceAlreadyRegistered:
            presentWarningSnackbar(title: "\(action.title): the device is already registered")
        case .noSessionTokens:
            presentWarningSnackbar(title: "\(action.title): there are no session tokens")
        }
    }

    private static func presentSuccessSnackbar(title: String) {
        presentSnackbar(title: title, icon: DesignSystem.Icons.Checkmark.regular20, iconColor: DesignSystem.Color.iconAccentBlue)
    }

    private static func presentWarningSnackbar(title: String) {
        presentSnackbar(title: title, icon: DesignSystem.Icons.Warning.filled20, iconColor: DesignSystem.Color.iconStatusWarning)
    }

    private static func presentSnackbar(title: String, icon: ImageType, iconColor: Color) {
        let snackbar = TangemSnackbar(title: title)
            .icon(icon)
            .iconColor(iconColor)

        Toast(view: snackbar).present(layout: .top(padding: Constants.snackbarPadding), type: .temporary())
    }
}

// MARK: - Rows

private extension BackendAuthenticationDebugViewModel {
    var environmentDescription: String {
        "\(environmentName.uppercased()) (\(baseURL.absoluteString))"
    }

    func makeDevicePublicKeyRow() async -> ValueRow {
        let title = "Device public key (SPKI)"

        do {
            let devicePublicKey = try await debugService.devicePublicKey()
            let spki = devicePublicKey.derRepresentation.base64EncodedString()

            return ValueRow(title: title, value: .text(shortened(spki)), subtitle: nil, copyValue: spki)
        } catch {
            return ValueRow(title: title, value: .text("unavailable: \(error)"), subtitle: nil, copyValue: nil)
        }
    }

    func makeRegisteredWalletRows() async -> [UserWalletInfo] {
        var registeredUserWalletInfos: [UserWalletInfo] = []

        for userWalletInfo in userWalletInfos {
            if await retrieveUserWalletRegistrationStatus(id: userWalletInfo.id) {
                registeredUserWalletInfos.append(userWalletInfo)
            }
        }

        return registeredUserWalletInfos
    }

    func makeSessionRows() async -> [ValueRow] {
        let title = "Session tokens"
        let sessionTokens: SessionTokens?

        do {
            sessionTokens = try await debugService.sessionTokens()
        } catch {
            return [ValueRow(title: title, value: .text("error: \(error)"), subtitle: nil, copyValue: nil)]
        }

        guard let sessionTokens else {
            return [ValueRow(title: title, value: .flag(false), subtitle: nil, copyValue: nil)]
        }

        let refreshTokenTitle = "Refresh token"
        let refreshTokenRow: ValueRow

        if let refreshToken = sessionTokens.refreshToken {
            refreshTokenRow = makeTokenRow(title: refreshTokenTitle, token: refreshToken)
        } else {
            refreshTokenRow = ValueRow(title: refreshTokenTitle, value: .text("none"), subtitle: nil, copyValue: nil)
        }

        return [
            ValueRow(title: title, value: .flag(true), subtitle: nil, copyValue: nil),
            makeTokenRow(title: "Access token", token: sessionTokens.accessToken),
            refreshTokenRow,
            ValueRow(title: "Token wallets", value: .text(walletNames(for: sessionTokens.userWalletIDs)), subtitle: nil, copyValue: nil),
        ]
    }

    func makeTokenRow(title: String, token: SessionTokens.Token) -> ValueRow {
        guard token.jwt.isNotEmpty else {
            return ValueRow(
                title: title,
                value: .text(.emDashSign),
                subtitle: expirationDescription(for: token.expiresAt),
                copyValue: nil
            )
        }

        return ValueRow(
            title: title,
            value: .text(shortened(token.jwt)),
            subtitle: expirationDescription(for: token.expiresAt),
            copyValue: token.jwt
        )
    }

    func expirationDescription(for expiresAt: Date) -> String {
        let formattedDate = Self.expirationDateFormatter.string(from: expiresAt)
        let timeLeft = expiresAt.timeIntervalSinceNow

        guard timeLeft > 0, let formattedTimeLeft = Self.remainingTimeFormatter.string(from: timeLeft) else {
            return "expires \(formattedDate) (expired)"
        }

        return "expires \(formattedDate) (\(formattedTimeLeft) left)"
    }

    func walletNames(for userWalletIds: [UserWalletId]) -> String {
        guard userWalletIds.isNotEmpty else {
            return .emDashSign
        }

        let knownWalletNames = userWalletIds.compactMap { id in
            userWalletInfos.first { $0.id == id }?.name
        }
        let unknownWalletsCount = userWalletIds.count - knownWalletNames.count

        guard unknownWalletsCount > 0 else {
            return knownWalletNames.joined(separator: ", ")
        }

        return (knownWalletNames + ["\(unknownWalletsCount) unknown"]).joined(separator: ", ")
    }

    func shortened(_ value: String) -> String {
        guard value.count > Constants.shortenedSideLength * 2 + 1 else {
            return value
        }

        return "\(value.prefix(Constants.shortenedSideLength))…\(value.suffix(Constants.shortenedSideLength))"
    }
}

// MARK: - Auxiliary types

public extension BackendAuthenticationDebugViewModel {
    // [REDACTED_TODO_COMMENT]
    struct UserWalletInfo: Sendable {
        let id: UserWalletId
        let name: String

        public init(id: UserWalletId, name: String) {
            self.id = id
            self.name = name
        }
    }
}

extension BackendAuthenticationDebugViewModel {
    struct ValueRow: Identifiable {
        var id: String { title }

        let title: String
        let value: Value
        let subtitle: String?
        let copyValue: String?

        enum Value {
            case text(String)
            case flag(Bool)
        }
    }

    enum Action: Hashable {
        case registerDevice
        case resetDeviceRegistration
        case unregisterUserWallet(UserWalletId)
        case forceRefresh
        case corruptAccessToken
        case expireAccessToken
        case setAccessTokenExpiration
        case clearSessionTokens

        var title: String {
            switch self {
            case .registerDevice: "Register device"
            case .resetDeviceRegistration: "Reset registration"
            case .unregisterUserWallet: "Unregister wallet"
            case .forceRefresh: "Force refresh"
            case .corruptAccessToken: "Corrupt access token"
            case .expireAccessToken: "Expire access token"
            case .setAccessTokenExpiration: "Set access token expiry"
            case .clearSessionTokens: "Clear session tokens"
            }
        }
    }

    enum ActionOutcome {
        case completed
        case deviceAlreadyRegistered
        case noSessionTokens
    }
}

// MARK: - Constants

extension BackendAuthenticationDebugViewModel {
    enum Constants {
        static let shortenedSideLength = 6
        static let snackbarPadding: CGFloat = 14
    }
}
