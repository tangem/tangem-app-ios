//
//  ForceUpdateViewModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Testing
import TangemLocalization
@testable import Tangem

@Suite("Force update screen")
struct ForceUpdateViewModelTests {
    @Test("Each screen reports its own notice when it is shown", arguments: [
        ForceUpdateReason.requiresAppUpdate,
        .brick,
        .requiresOSUpdate,
    ])
    func reportsScreenShown(reason: ForceUpdateReason) async {
        await withForceUpdateService(ForceUpdateServiceStub()) {
            let logger = ForceUpdateAnalyticsLoggerSpy()

            _ = ForceUpdateViewModel(reason: reason, analyticsLogger: logger, coordinator: ForceUpdateRoutableSpy())

            #expect(logger.events == [.screenShown(reason)])
        }
    }

    @Test("Update now reports the tap and opens the App Store")
    func updateNow() async {
        await withForceUpdateService(ForceUpdateServiceStub()) {
            let logger = ForceUpdateAnalyticsLoggerSpy()
            let routable = ForceUpdateRoutableSpy()
            let viewModel = ForceUpdateViewModel(reason: .requiresAppUpdate, analyticsLogger: logger, coordinator: routable)

            viewModel.primaryButton?.action()

            #expect(logger.events == [.screenShown(.requiresAppUpdate), .updateNowTapped])
            #expect(routable.calls == [.openAppStore])
        }
    }

    @Test("Contact support reports the screen it was tapped on and opens support", arguments: [
        (ForceUpdateReason.requiresAppUpdate, ForceUpdateSupportSource.criticalUpdate),
        (.brick, .unsupportedDevice),
    ])
    func contactSupport(reason: ForceUpdateReason, source: ForceUpdateSupportSource) async throws {
        try await withForceUpdateService(ForceUpdateServiceStub()) {
            let logger = ForceUpdateAnalyticsLoggerSpy()
            let routable = ForceUpdateRoutableSpy()
            let viewModel = ForceUpdateViewModel(reason: reason, analyticsLogger: logger, coordinator: routable)

            let supportButton = try #require(
                [viewModel.primaryButton, viewModel.secondaryButton]
                    .compactMap { $0 }
                    .first { $0.title == Localization.commonContactSupport }
            )
            supportButton.action()

            #expect(logger.events == [.screenShown(reason), .contactSupportTapped(source)])
            #expect(routable.calls == [.openSupport])
        }
    }

    @Test("The OS update screen offers no way to contact support")
    func osUpdateHasNoSupport() async {
        await withForceUpdateService(ForceUpdateServiceStub()) {
            let viewModel = ForceUpdateViewModel(
                reason: .requiresOSUpdate,
                analyticsLogger: ForceUpdateAnalyticsLoggerSpy(),
                coordinator: ForceUpdateRoutableSpy()
            )

            #expect(viewModel.primaryButton == nil)
            #expect(viewModel.secondaryButton?.title == Localization.commonLater)
        }
    }

    @Test("Later reports the tap, dismisses the OS warning and closes the screen")
    func later() async {
        let service = ForceUpdateServiceStub()

        await withForceUpdateService(service) {
            let logger = ForceUpdateAnalyticsLoggerSpy()
            let routable = ForceUpdateRoutableSpy()
            let viewModel = ForceUpdateViewModel(reason: .requiresOSUpdate, analyticsLogger: logger, coordinator: routable)

            viewModel.secondaryButton?.action()

            #expect(logger.events == [.screenShown(.requiresOSUpdate), .laterTapped])
            #expect(service.dismissOSUpdateWarningCallsCount == 1)
            #expect(routable.calls == [.closeForceUpdate])
        }
    }
}

// MARK: - Helpers

private func withForceUpdateService<T>(
    _ service: ForceUpdateService,
    operation: () async throws -> T
) async rethrows -> T {
    try await InjectedDependenciesIsolation.shared.run {
        let previous = InjectedValues[\.forceUpdateService]
        InjectedValues[\.forceUpdateService] = service
        defer { InjectedValues[\.forceUpdateService] = previous }
        return try await operation()
    }
}

private final class ForceUpdateAnalyticsLoggerSpy: ForceUpdateAnalyticsLogger {
    enum Event: Equatable {
        case screenShown(ForceUpdateReason)
        case updateNowTapped
        case contactSupportTapped(ForceUpdateSupportSource)
        case laterTapped
    }

    private(set) var events: [Event] = []

    func logScreenShown(reason: ForceUpdateReason) {
        events.append(.screenShown(reason))
    }

    func logUpdateNowTapped() {
        events.append(.updateNowTapped)
    }

    func logContactSupportTapped(source: ForceUpdateSupportSource) {
        events.append(.contactSupportTapped(source))
    }

    func logLaterTapped() {
        events.append(.laterTapped)
    }
}

private final class ForceUpdateRoutableSpy: ForceUpdateRoutable {
    enum Call: Equatable {
        case closeForceUpdate
        case openSupport
        case openAppStore
    }

    private(set) var calls: [Call] = []

    func closeForceUpdate() {
        calls.append(.closeForceUpdate)
    }

    func openSupport() {
        calls.append(.openSupport)
    }

    func openAppStore() {
        calls.append(.openAppStore)
    }
}

private final class ForceUpdateServiceStub: ForceUpdateService {
    private(set) var dismissOSUpdateWarningCallsCount = 0

    var statePublisher: AnyPublisher<ForceUpdateState, Never> {
        Empty().eraseToAnyPublisher()
    }

    var startupBlockingReason: ForceUpdateReason? {
        nil
    }

    func refreshCache() {}

    func refreshAndApply() {}

    func dismissOSUpdateWarning() {
        dismissOSUpdateWarningCallsCount += 1
    }
}
