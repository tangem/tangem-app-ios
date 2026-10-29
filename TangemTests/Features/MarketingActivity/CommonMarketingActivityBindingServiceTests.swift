//
//  CommonMarketingActivityBindingServiceTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import Moya
import Testing
import TangemFoundation
import TangemNetworkUtils
@testable import Tangem

@Suite("Marketing activity binding service", .serialized, .timeLimit(.minutes(1)))
@MainActor
struct CommonMarketingActivityBindingServiceTests {
    private let storage = InMemoryPersistentStorage()
    private let reachability = NetworkReachabilityProviderStub()
    private let api = BindWalletsApiSpy()
    private let storeEvents = BindingStoreEvents()

    private let walletA = Self.makeWallet(0xA1)
    private let walletB = Self.makeWallet(0xB2)

    @Test("With wallets on the device the uid is bound at once, every wallet once")
    func bindsOnReceive() async throws {
        let repository = UserWalletRepositoryStub(models: [walletA, walletA, walletB])
        let sut = makeSUT(repository: repository)

        sut.initialize()
        sut.register(uid: "uid-1")

        #expect(await api.nextCall() == makeCall(wallets: [walletA, walletB]))
        await storeEvents.waitFor(.removed(uid: "uid-1"))
        #expect(try storedBindings().isEmpty)
    }

    @Test("A locked app doesn't hold the request back: locked wallets are known too")
    func bindsWhileLocked() async {
        let repository = UserWalletRepositoryStub(models: [walletA], isLocked: true)
        let sut = makeSUT(repository: repository)

        sut.initialize()
        sut.register(uid: "uid-1")

        #expect(await api.nextCall() == makeCall())
    }

    @Test("Without wallets the uid waits and goes out once the first wallet appears")
    func waitsForFirstWallet() async throws {
        let repository = UserWalletRepositoryStub(models: [])
        let sut = makeSUT(repository: repository)

        sut.initialize()
        sut.register(uid: "uid-1")

        await storeEvents.waitFor(.added(uid: "uid-1"))
        #expect(try storedBindings().map(\.uid) == ["uid-1"])

        repository.add(walletA)

        #expect(await api.nextCall() == makeCall())
    }

    @Test("A wallet that appears while the service starts watching wallets isn't missed")
    func walletAddedWhileSubscribingIsNotMissed() async {
        let repository = UserWalletRepositoryStub(models: [])
        repository.addOnSubscription(walletA)
        let sut = makeSUT(repository: repository)

        sut.initialize()
        sut.register(uid: "uid-1")

        #expect(await api.nextCall() == makeCall())
    }

    @Test("The same uid opened twice before the first wallet is one request")
    func sameUidBeforeFirstWallet() async throws {
        let repository = UserWalletRepositoryStub(models: [])
        let sut = makeSUT(repository: repository)

        sut.initialize()
        sut.register(uid: "uid-1")
        sut.register(uid: "uid-1")
        sut.register(uid: "uid-2")

        await storeEvents.waitFor(.added(uid: "uid-2"))
        #expect(try storedBindings().map(\.uid) == ["uid-1", "uid-2"])

        repository.add(walletA)

        await storeEvents.waitFor(.removed(uid: "uid-2"))
        #expect(api.calls == [makeCall(), makeCall(uid: "uid-2")])
    }

    @Test("Opening the link again after its request went out sends it again")
    func reopeningSendsAgain() async {
        let repository = UserWalletRepositoryStub(models: [walletA])
        let sut = makeSUT(repository: repository)

        sut.initialize()
        sut.register(uid: "uid-1")
        #expect(await api.nextCall() == makeCall())
        await storeEvents.waitFor(.removed(uid: "uid-1"))

        sut.register(uid: "uid-1")

        #expect(await api.nextCall() == makeCall())
    }

    @Test("Each request carries the wallets the device has when it goes out")
    func walletAddedDuringDeliveryGoesOutWithNextRequest() async {
        await makeStore().add(uid: "uid-1")
        await makeStore().add(uid: "uid-2")

        let repository = UserWalletRepositoryStub(models: [walletA])
        let sut = makeSUT(repository: repository)
        let walletB = walletB
        api.onFirstCall {
            await MainActor.run { repository.add(walletB) }
        }

        sut.initialize()

        #expect(await api.nextCall() == makeCall())
        #expect(await api.nextCall() == makeCall(uid: "uid-2", wallets: [walletA, walletB]))
    }

    @Test("A request left from the previous launch goes out on the next one")
    func deliversOnLaunch() async {
        await makeStore().add(uid: "uid-1")

        let repository = UserWalletRepositoryStub(models: [walletA])
        let sut = makeSUT(repository: repository)

        sut.initialize()

        #expect(await api.nextCall() == makeCall())
    }

    @Test("A uid opened before the services start is saved and sent once they do, not before")
    func registeredBeforeStart() async throws {
        let repository = UserWalletRepositoryStub(models: [walletA])
        let sut = makeSUT(repository: repository)

        sut.register(uid: "uid-1")
        #expect(try storedBindings().isEmpty)
        #expect(api.calls.isEmpty)

        sut.initialize()

        #expect(await api.nextCall() == makeCall())
        await storeEvents.waitFor(.removed(uid: "uid-1"))
        #expect(api.calls == [makeCall()])
    }

    @Test("A request that failed is retried once the network comes back")
    func retriesFailureOnNetworkRestore() async throws {
        await makeStore().add(uid: "uid-1")

        let repository = UserWalletRepositoryStub(models: [walletA])
        let sut = makeSUT(repository: repository)
        api.failNext(with: MoyaError.underlying(URLError(.notConnectedToInternet), nil))

        sut.initialize()
        #expect(await api.nextCall() == makeCall())

        reachability.set(isReachable: false)
        reachability.set(isReachable: true)

        #expect(await api.nextCall() == makeCall())
        await storeEvents.waitFor(.removed(uid: "uid-1"))
        #expect(try storedBindings().isEmpty)
    }

    @Test("A new uid first retries the requests that were waiting before it")
    func newUidRetriesWaitingRequests() async throws {
        await makeStore().add(uid: "uid-1")

        let repository = UserWalletRepositoryStub(models: [walletA])
        let sut = makeSUT(repository: repository)
        api.failNext(with: MoyaError.statusCode(Response(statusCode: 503, data: Data())))

        sut.initialize()
        #expect(await api.nextCall() == makeCall())

        sut.register(uid: "uid-2")

        #expect(await api.nextCall() == makeCall())
        #expect(await api.nextCall() == makeCall(uid: "uid-2"))
        await storeEvents.waitFor(.removed(uid: "uid-2"))
        #expect(try storedBindings().isEmpty)
    }

    @Test("A request the backend rejects is dropped and never retried", arguments: [400, 401, 403, 404, 422])
    func dropsRejected(statusCode: Int) async throws {
        let repository = UserWalletRepositoryStub(models: [walletA])
        let sut = makeSUT(repository: repository)
        api.failNext(with: MoyaError.statusCode(Response(statusCode: statusCode, data: Data())))

        sut.initialize()
        sut.register(uid: "uid-1")

        await storeEvents.waitFor(.removed(uid: "uid-1"))
        #expect(try storedBindings().isEmpty)

        reachability.set(isReachable: false)
        reachability.set(isReachable: true)
        sut.register(uid: "uid-2")

        #expect(await api.nextCall() == makeCall())
        #expect(await api.nextCall() == makeCall(uid: "uid-2"))
    }

    @Test("A timed out, throttled or failing answer keeps the request for the next launch", arguments: [408, 429, 500, 503])
    func keepsTemporaryFailureForNextLaunch(statusCode: Int) async throws {
        await makeStore().add(uid: "uid-1")

        let repository = UserWalletRepositoryStub(models: [walletA])
        var firstLaunch: CommonMarketingActivityBindingService? = makeSUT(repository: repository)
        api.failNext(with: MoyaError.statusCode(Response(statusCode: statusCode, data: Data())))

        firstLaunch?.initialize()
        #expect(await api.nextCall() == makeCall())

        await release(&firstLaunch)
        #expect(try storedBindings().map(\.uid) == ["uid-1"])

        let secondLaunch = makeSUT(repository: repository)
        secondLaunch.initialize()

        #expect(await api.nextCall() == makeCall())
        await storeEvents.waitFor(.removed(uid: "uid-1"))
        #expect(try storedBindings().isEmpty)
    }

    @Test("Initializing twice starts the service once")
    func initializesOnce() async {
        await makeStore().add(uid: "uid-1")

        let repository = UserWalletRepositoryStub(models: [walletA])
        var sut: CommonMarketingActivityBindingService? = makeSUT(repository: repository)

        sut?.initialize()
        sut?.initialize()

        #expect(await api.nextCall() == makeCall())
        await storeEvents.waitFor(.removed(uid: "uid-1"))

        await release(&sut)
        #expect(api.calls == [makeCall()])
    }

    @Test("A uid received while locked wallets aren't known goes out on unlock")
    func sendsOnUnlockWhenWalletsWereHidden() async {
        let repository = UserWalletRepositoryStub(models: [walletA])
        let sut = makeSUT(repository: repository)

        sut.initialize()
        await storeEvents.waitFor(.pending(uids: []))

        let wallets = repository.lockForgettingWallets()
        sut.register(uid: "uid-1")
        await storeEvents.waitFor(.added(uid: "uid-1"))

        repository.unlock(restoring: wallets)

        #expect(await api.nextCall() == makeCall())
    }

    @Test("A request that keeps failing is tried once per trigger, not in a loop")
    func failingRequestIsTriedOncePerTrigger() async throws {
        await makeStore().add(uid: "uid-1")

        let repository = UserWalletRepositoryStub(models: [walletA])
        var sut: CommonMarketingActivityBindingService? = makeSUT(repository: repository)
        api.failNext(with: MoyaError.statusCode(Response(statusCode: 503, data: Data())))
        api.failNext(with: MoyaError.statusCode(Response(statusCode: 503, data: Data())))

        sut?.initialize()
        #expect(await api.nextCall() == makeCall())

        reachability.set(isReachable: false)
        reachability.set(isReachable: true)

        #expect(await api.nextCall() == makeCall())

        await release(&sut)
        #expect(api.calls == [makeCall(), makeCall()])
        #expect(try storedBindings().map(\.uid) == ["uid-1"])
    }

    @Test("Adding the first wallet to a locked app makes one attempt")
    func firstWalletInLockedAppMakesOneAttempt() async throws {
        let repository = UserWalletRepositoryStub(models: [])
        var sut: CommonMarketingActivityBindingService? = makeSUT(repository: repository)
        api.failNext(with: MoyaError.underlying(URLError(.notConnectedToInternet), nil))

        sut?.initialize()
        sut?.register(uid: "uid-1")
        await storeEvents.waitFor(.added(uid: "uid-1"))

        repository.addWhileLocked(walletA)

        #expect(await api.nextCall() == makeCall())

        await release(&sut)
        #expect(api.calls == [makeCall()])
        #expect(try storedBindings().map(\.uid) == ["uid-1"])
    }
}

// MARK: - Helpers

private extension CommonMarketingActivityBindingServiceTests {
    func makeStore() -> CommonMarketingActivityBindingStore {
        CommonMarketingActivityBindingStore(persistentStorage: storage)
    }

    func makeSUT(repository: UserWalletRepository) -> CommonMarketingActivityBindingService {
        CommonMarketingActivityBindingService(
            userWalletRepository: repository,
            apiService: api.service,
            store: BindingStoreSpy(store: makeStore(), events: storeEvents),
            reachabilityProvider: reachability
        )
    }

    func makeCall(uid: String = "uid-1", wallets: [FakeUserWalletModel]? = nil) -> BindWalletsApiSpy.Call {
        BindWalletsApiSpy.Call(uid: uid, walletIds: (wallets ?? [walletA]).map(\.userWalletId.stringValue))
    }

    func storedBindings() throws -> [MarketingActivityBinding] {
        try storage.value(for: .marketingActivityBindings) ?? []
    }

    func release(_ sut: inout CommonMarketingActivityBindingService?) async {
        sut = nil
        await storeEvents.waitFor(.released)
    }

    static func makeWallet(_ byte: UInt8) -> FakeUserWalletModel {
        FakeUserWalletModel(
            userWalletName: "Wallet",
            isUserWalletLocked: false,
            isDelayed: false,
            cardsCount: 1,
            userWalletId: UserWalletId(value: Data(repeating: byte, count: 32)),
            walletManagers: [],
            config: UserWalletConfigStubs.walletV2Stub
        )
    }
}

// MARK: - Stubs

private final class UserWalletRepositoryStub: FakeUserWalletRepository {
    private let locked: Bool
    private let events = PassthroughSubject<UserWalletRepositoryEvent, Never>()
    private var walletToAddOnSubscription: UserWalletModel?

    override var isLocked: Bool {
        locked
    }

    override var eventProvider: AnyPublisher<UserWalletRepositoryEvent, Never> {
        Deferred { [self] in
            if let wallet = walletToAddOnSubscription {
                walletToAddOnSubscription = nil
                DispatchQueue.main.sync { add(wallet) }
            }

            return events
        }
        .eraseToAnyPublisher()
    }

    init(models: [UserWalletModel], isLocked: Bool = false) {
        locked = isLocked
        super.init(models: models)
    }

    func add(_ wallet: UserWalletModel) {
        models.append(wallet)
        events.send(.selected(userWalletId: wallet.userWalletId))
    }

    func addOnSubscription(_ wallet: UserWalletModel) {
        walletToAddOnSubscription = wallet
    }

    func lockForgettingWallets() -> [UserWalletModel] {
        let wallets = models
        models = []
        events.send(.locked)
        return wallets
    }

    func unlock(restoring wallets: [UserWalletModel]) {
        models = wallets
        events.send(.unlocked)
    }

    func addWhileLocked(_ wallet: UserWalletModel) {
        models.append(wallet)
        events.send(.unlocked)
        events.send(.selected(userWalletId: wallet.userWalletId))
    }
}

private final class NetworkReachabilityProviderStub: NetworkReachabilityProvider, @unchecked Sendable {
    private let subject = CurrentValueSubject<Bool, Never>(true)

    var isReachable: Bool {
        subject.value
    }

    var isReachablePublisher: AnyPublisher<Bool, Never> {
        subject.removeDuplicates().eraseToAnyPublisher()
    }

    func set(isReachable: Bool) {
        subject.send(isReachable)
    }
}

private final class BindWalletsApiSpy {
    struct Call: Equatable, Sendable {
        let uid: String
        let walletIds: [String]
    }

    private struct State {
        var calls: [Call] = []
        var failures: [any Error] = []
        var firstCallAction: (() async -> Void)?
    }

    let service = FakeTangemApiService()
    private let state = OSAllocatedUnfairLock(initialState: State())
    private let (callStream, callContinuation) = AsyncStream<Call>.makeStream()

    var calls: [Call] {
        state.withLock { $0.calls }
    }

    init() {
        service.bindMarketingActivityWalletsHandler = { [state, callContinuation] uid, request in
            let call = Call(uid: uid, walletIds: request.walletIds)
            let (failure, firstCallAction) = state.withLock { state in
                state.calls.append(call)
                let failure = state.failures.isEmpty ? nil : state.failures.removeFirst()
                let firstCallAction = state.calls.count == 1 ? state.firstCallAction : nil
                return (failure, firstCallAction)
            }

            callContinuation.yield(call)
            await firstCallAction?()

            if let failure {
                throw failure
            }
        }
    }

    func failNext(with error: any Error) {
        state.withLock { $0.failures.append(error) }
    }

    func onFirstCall(_ action: @escaping () async -> Void) {
        state.withLock { $0.firstCallAction = action }
    }

    func nextCall() async -> Call? {
        for await call in callStream {
            return call
        }

        return nil
    }
}

private final class BindingStoreEvents: Sendable {
    enum Event: Equatable, Sendable {
        case added(uid: String)
        case pending(uids: [String])
        case removed(uid: String)
        case released
    }

    private let (stream, continuation) = AsyncStream<Event>.makeStream()

    func send(_ event: Event) {
        continuation.yield(event)
    }

    func waitFor(_ event: Event) async {
        for await received in stream where received == event {
            return
        }
    }
}

private actor BindingStoreSpy: MarketingActivityBindingStore {
    private let store: CommonMarketingActivityBindingStore
    private let events: BindingStoreEvents

    init(store: CommonMarketingActivityBindingStore, events: BindingStoreEvents) {
        self.store = store
        self.events = events
    }

    deinit {
        events.send(.released)
    }

    func add(uid: String) async -> MarketingActivityBinding {
        let binding = await store.add(uid: uid)
        events.send(.added(uid: uid))
        return binding
    }

    func pending() async -> [MarketingActivityBinding] {
        let bindings = await store.pending()
        events.send(.pending(uids: bindings.map(\.uid)))
        return bindings
    }

    func remove(id: UUID) async {
        let removed = await store.pending().filter { $0.id == id }
        await store.remove(id: id)
        removed.forEach { events.send(.removed(uid: $0.uid)) }
    }
}
