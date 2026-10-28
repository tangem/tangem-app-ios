//
//  CommonPushNotificationsInteractorTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Testing
import TangemFoundation
@testable import Tangem

@Suite("CommonPushNotificationsInteractor — after-login permission request")
@MainActor
struct CommonPushNotificationsInteractorTests {
    @Test("Permission granted in the app stops the after-login request from the next launch")
    func permissionGrantedInAppStopsRequestOnNextLaunch() async {
        await withStubbedService { service in
            let firstLaunch = makeInitializedInteractor()
            firstLaunch.suppressAfterLoginRequestsInCurrentSession()

            service.events.send(.authorization(.granted))
            await drainMainQueue()
            withExtendedLifetime(firstLaunch) {}

            let nextLaunch = makeInitializedInteractor()

            #expect(nextLaunch.isAvailable(in: .afterLogin) == false)
        }
    }

    @Test("Permission already granted when the app becomes active stops the after-login request")
    func permissionGrantedOnActivationStopsRequest() async {
        await withStubbedService { service in
            let interactor = makeInitializedInteractor()

            service.authorizationOnActivation.send(true)
            await drainMainQueue()

            #expect(interactor.isAvailable(in: .afterLogin) == false)
        }
    }

    @Test("The after-login request stays available while permission is not granted")
    func requestStaysAvailableWithoutPermission() async {
        await withStubbedService { service in
            let interactor = makeInitializedInteractor()

            service.authorizationOnActivation.send(false)
            service.events.send(.authorization(.deniedOrUndetermined))
            await drainMainQueue()

            #expect(interactor.isAvailable(in: .afterLogin))
        }
    }

    // MARK: - Helpers

    private func withStubbedService(_ operation: (PushNotificationsServiceStub) async -> Void) async {
        await InjectedDependenciesIsolation.shared.run {
            let previousService = InjectedValues[\.pushNotificationsService]
            let service = PushNotificationsServiceStub()
            InjectedValues[\.pushNotificationsService] = service
            removeStoredRequestState()

            defer {
                removeStoredRequestState()
                InjectedValues[\.pushNotificationsService] = previousService
            }

            await operation(service)
        }
    }

    private func makeInitializedInteractor() -> CommonPushNotificationsInteractor {
        let interactor = CommonPushNotificationsInteractor()
        interactor.initialize()
        return interactor
    }

    private func drainMainQueue() async {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                continuation.resume()
            }
        }
    }

    private func removeStoredRequestState() {
        let store = UserDefaults(suiteName: AppEnvironment.current.suiteName)

        [
            "can_request_authorization",
            "did_postpone_authorization_request_on_wallet_onboarding",
            "did_request_authorization_on_after_login",
            "reset_push_notifications_authorization_request_counter",
            "did_postpone_onboarding_completion_date",
        ].forEach { store?.removeObject(forKey: $0) }
    }
}

// MARK: - Stubs

private final class PushNotificationsServiceStub: PushNotificationsService {
    let events = PassthroughSubject<PushNotificationsEvent, Never>()
    let authorizationOnActivation = PassthroughSubject<Bool, Never>()

    @MainActor
    var isAuthorized: Bool {
        get async { false }
    }

    var isAuthorizedPublisher: AnyPublisher<Bool, Never> {
        authorizationOnActivation.eraseToAnyPublisher()
    }

    var eventsPublisher: AnyPublisher<PushNotificationsEvent, Never> {
        events.eraseToAnyPublisher()
    }

    func requestAuthorizationAndRegister() async {}

    func registerIfPossible() async {}
}
