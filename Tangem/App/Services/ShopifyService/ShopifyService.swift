//
//  ShopifyService.swift
//  TangemShopify
//
//  Created by [REDACTED_AUTHOR]
//

import MobileBuySDK
import Combine
import PassKit

enum ShopifyError: Error {
    case unknown
    case applePayFailed
    case userError(errors: [DisplayableError])
}

class ShopifyService {
    private let client: Graph.Client
    private let shop: ShopifyShop
    private let testApplePayPayments: Bool
    
    private var paySession: PaySession?
    private var paySessionPublisher: PassthroughSubject<Checkout, Error>?
    
    private var subscriptions: Set<AnyCancellable> = []
    
    private var tasks: [Task] = []
        
    // MARK: -
    
    init(shop: ShopifyShop, testApplePayPayments: Bool) {
        self.client = Graph.Client(shopDomain: shop.domain, apiKey: shop.storefrontApiKey, locale: Locale.current)
        self.shop = shop
        self.testApplePayPayments = testApplePayPayments
    }
    
    deinit {
        cancelTasks()
        print("ShopifyService deinitialized")
    }
    
    private func runTask(_ task: Task) {
        task.resume()
        tasks.append(task)
    }
    
    func cancelTasks() {
        print("Shopify: Cancelling tasks")
        tasks.forEach { $0.cancel() }
    }
    
    // MARK: - Getting data
    
    func shopName() -> AnyPublisher<String, Error> {
        let query = Storefront.buildQuery { $0
            .shop { $0
                .name()
            }
        }
        
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(ShopifyError.unknown))
                return
            }
            
            let task = self.client.queryGraphWith(query) { query, error in
                if let query = query {
                    promise(.success(query.shop.name))
                    return
                }
                
                if let error = error {
                    print("Failed to get shop info")
                    promise(.failure(error))
                    return
                }
                
                promise(.failure(ShopifyError.unknown))
            }
            
            self.runTask(task)
        }.eraseToAnyPublisher()
    }
    
    func products(collectionTitleFilter: String? = nil) -> AnyPublisher<[Collection], Error> {
        let filter: String?
        if let titleFilter = collectionTitleFilter {
            filter = "title:\"\(titleFilter)\""
        } else {
            filter = nil
        }
        
        let query = Storefront.buildQuery { $0
            .collections(first: 250, query: filter) { $0
                .edges { $0
                    .node { $0
                        .collectionFieldsFragment()
                    }
                }
            }
        }

        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(ShopifyError.unknown))
                return
            }
            
            let task = self.client.queryGraphWith(query) { response, error in
                if let response = response {
                    let collections = response.collections.edges.map { Collection($0.node) }
                    promise(.success(collections))
                    return
                }
                
                if let error = error {
                    print("Failed to get collections", error)
                    promise(.failure(error))
                    return
                }
                
                print("Failed to get collections")
                promise(.failure(ShopifyError.unknown))
            }
            
            self.runTask(task)
        }
        .eraseToAnyPublisher()
    }
    
    func checkout(pollUntilOrder: Bool, checkoutID: GraphQL.ID) -> AnyPublisher<Checkout, Error> {
        let query = Storefront.buildQuery { $0
            .node(id: checkoutID) { $0
                .onCheckout { $0
                    .checkoutFieldsFragment()
                }
            }
        }
        
        let future: Future<Checkout, Error> = Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(ShopifyError.unknown))
                return
            }
            
            let retryHandler: Graph.RetryHandler<Storefront.QueryRoot>  = .init() { response, error in
                guard pollUntilOrder else { return false }
                
                guard
                    let checkout = response?.node as? Storefront.Checkout,
                    let _ = checkout.order
                else {
                    print("Not ordered yet, continuing polling")
                    return true
                }
                
                return false
            }
            
            let task = self.client.queryGraphWith(query, retryHandler: retryHandler) { response, error in
                if let queriedCheckout = response?.node as? Storefront.Checkout {
                    promise(.success(Checkout(queriedCheckout)))
                    return
                }
                
                if let error = error {
                    print("Failed to get checkout", error)
                    promise(.failure(error))
                    return
                }
                
                print("Failed to get checkout")
                promise(.failure(ShopifyError.unknown))
            }
            self.runTask(task)
        }
        
        return future.eraseToAnyPublisher()
    }
    
    // MARK: - Updating checkout
    
    private func retryHandler(
        checkShippingRates: Bool,
        payloadProvider: @escaping (Storefront.Mutation) -> CheckoutPayload?
    ) -> Graph.RetryHandler<Storefront.Mutation> {
        // Return true if request needs to be retried
        .init { response, error in
            guard let response = response else { return true }
            
            let payload = payloadProvider(response)
            let checkout = payload?.checkout
            
            if let userErrors = payload?.checkoutUserErrors, !userErrors.isEmpty {
                print("User errors:", userErrors)
                return false
            }
            
            if checkShippingRates && checkout?.availableShippingRates?.ready != true {
                print("Shipping rates not ready, continue polling")
                return true
            }

            if let checkoutReady = checkout?.ready, !checkoutReady {
                print("Checkout is not ready, continue polling")
                return true
            }
            
            return false
        }
    }
    
    private func runCheckoutMutation(
        mutation: Storefront.MutationQuery,
        description: String,
        checkShippingRates: Bool = false,
        payloadProvider: @escaping (Storefront.Mutation) -> CheckoutPayload?
    ) -> AnyPublisher<Checkout, Error> {
        Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(ShopifyError.unknown))
                return
            }
            
            let retryHandler = self.retryHandler(checkShippingRates: checkShippingRates, payloadProvider: payloadProvider)
            let task = self.client.mutateGraphWith(mutation, retryHandler: retryHandler) { mutation, error in
                guard
                    let mutation = mutation,
                    let payload = payloadProvider(mutation)
                else {
                    print("No payload received")
                    promise(.failure(ShopifyError.unknown))
                    return
                }
                
                if let checkout = payload.checkout {
                    promise(.success(Checkout(checkout)))
                    return
                }
                
                let userErrors = payload.checkoutUserErrors
                if !userErrors.isEmpty {
                    print("Checkout modification failed (\(description)):", userErrors)
                    promise(.failure(ShopifyError.userError(errors: userErrors)))
                    return
                }
                
                if let error = error {
                    print("Checkout modification failed (\(description)):", error)
                    promise(.failure(error))
                    return
                }
                
                print("Checkout modification failed (\(description)):")
                promise(.failure(ShopifyError.unknown))
            }
            
            self.runTask(task)
        }
        .eraseToAnyPublisher()
    }
    
    func createCheckout(checkoutID: GraphQL.ID?, lineItems: [CheckoutLineItem]) -> AnyPublisher<Checkout, Error> {
        let storefrontLineItems: [Storefront.CheckoutLineItemInput] = lineItems.map { .create(quantity: $0.quantity, variantId: $0.id) }
        if let checkoutID = checkoutID {
            let mutation = Storefront.buildMutation { $0
                .checkoutLineItemsReplace(lineItems: storefrontLineItems, checkoutId: checkoutID) { $0
                    .checkout { $0
                        .checkoutFieldsFragment()
                    }
                    .userErrors { $0
                        .checkoutUserErrorFields()
                    }
                }
            }
            return runCheckoutMutation(mutation: mutation, description: "Replacing checkout items") {
                $0.checkoutLineItemsReplace
            }
        } else {
            let checkout = Storefront.CheckoutCreateInput.create(lineItems: .value(storefrontLineItems), allowPartialAddresses: .value(true))
            let mutation = Storefront.buildMutation { $0
                .checkoutCreate(input: checkout) { $0
                    .checkout { $0
                        .checkoutFieldsFragment()
                    }
                    .checkoutUserErrors { $0
                        .checkoutUserErrorFields()
                    }
                }
            }
            return runCheckoutMutation(mutation: mutation, description: "Creating checkout") {
                $0.checkoutCreate
            }
        }
    }
    
    func applyDiscount(_ discountCode: String?, checkoutID: GraphQL.ID) -> AnyPublisher<Checkout, Error> {
        if let discountCode = discountCode {
            let mutation = Storefront.buildMutation { $0
                .checkoutDiscountCodeApplyV2(discountCode: discountCode, checkoutId: checkoutID) { $0
                    .checkout { $0
                        .checkoutFieldsFragment()
                    }
                    .checkoutUserErrors { $0
                        .checkoutUserErrorFields()
                    }
                }
            }
            return runCheckoutMutation(mutation: mutation, description: "Applying discount") {
                $0.checkoutDiscountCodeApplyV2
            }
        } else {
            let mutation = Storefront.buildMutation { $0
                .checkoutDiscountCodeRemove(checkoutId: checkoutID) { $0
                    .checkout { $0
                        .checkoutFieldsFragment()
                    }
                    .checkoutUserErrors { $0
                        .checkoutUserErrorFields()
                    }
                }
            }
            return runCheckoutMutation(mutation: mutation, description: "Removing discount") {
                $0.checkoutDiscountCodeRemove
            }
        }
    }
    
    func updateAddress(_ address: Address, checkoutID: GraphQL.ID, waitForShippingRates: Bool) -> AnyPublisher<Checkout, Error> {
        let input = address.mutationInput
        let mutation = Storefront.buildMutation { $0
            .checkoutShippingAddressUpdateV2(shippingAddress: input, checkoutId: checkoutID) { $0
                .checkout { $0
                    .checkoutFieldsFragment()
                }
                .checkoutUserErrors { $0
                    .checkoutUserErrorFields()
                }
            }
        }
        return runCheckoutMutation(mutation: mutation, description: "Updating checkout address", checkShippingRates: waitForShippingRates) {
            $0.checkoutShippingAddressUpdateV2
        }
    }
    
    func updateEmail(email: String, checkoutID: GraphQL.ID) -> AnyPublisher<Checkout, Error> {
        let mutation = Storefront.buildMutation { $0
            .checkoutEmailUpdateV2(checkoutId: checkoutID, email: email) { $0
                .checkout { $0
                    .checkoutFieldsFragment()
                }
                .checkoutUserErrors { $0
                    .checkoutUserErrorFields()
                }
            }
        }
        return runCheckoutMutation(mutation: mutation, description: "Updating email") {
            $0.checkoutEmailUpdateV2
        }
    }
    
    func updateShippingRate(handle: String, checkoutID: GraphQL.ID) -> AnyPublisher<Checkout, Error> {
        let mutation = Storefront.buildMutation { $0
            .checkoutShippingLineUpdate(checkoutId: checkoutID, shippingRateHandle: handle) { $0
                .checkout { $0
                    .checkoutFieldsFragment()
                }
                .checkoutUserErrors { $0
                    .checkoutUserErrorFields()
                }
            }
        }
        return runCheckoutMutation(mutation: mutation, description: "Updating shipping rate") {
            $0.checkoutShippingLineUpdate
        }
    }
    
    func completeWithTokenizedPayment(_ payment: Storefront.TokenizedPaymentInputV3, checkoutID: GraphQL.ID) -> AnyPublisher<Checkout, Error> {
        let mutation = Storefront.buildMutation { $0
            .checkoutCompleteWithTokenizedPaymentV3(checkoutId: checkoutID, payment: payment) { $0
                .checkout { $0
                    .checkoutFieldsFragment()
                }
                .checkoutUserErrors { $0
                    .checkoutUserErrorFields()
                }
            }
        }
        return runCheckoutMutation(mutation: mutation, description: "Completing tokenized payment") {
            $0.checkoutCompleteWithTokenizedPaymentV3
        }
    }
    
    // MARK: - Apple Pay
    
    func canUseApplePay() -> Bool {
        PKPaymentAuthorizationController.canMakePayments()
    }
    
    func startApplePaySession(checkoutID: GraphQL.ID) -> AnyPublisher<Checkout, Error> {
        guard self.paySession == nil else {
            print("Another pay session is in progress")
            return Fail<Checkout, Error>(error: ShopifyError.applePayFailed)
                .eraseToAnyPublisher()
        }
        
        checkout(pollUntilOrder: false, checkoutID: checkoutID)
            .zip(shopName())
            .sink { _ in
                
            } receiveValue: { [unowned self] checkout, shopName in
                self.paySession = PaySession(
                    shopName: shopName,
                    checkout: checkout.payCheckout,
                    currency: checkout.payCurrency,
                    merchantID: self.shop.merchantID
                )
                self.paySession?.delegate = self
                self.paySession?.authorize()
            }
            .store(in: &subscriptions)
        
        let paySessionPublisher = PassthroughSubject<Checkout, Error>()
        self.paySessionPublisher = paySessionPublisher
        return paySessionPublisher.eraseToAnyPublisher()
    }
}

// MARK: - Apple Pay delegate

extension ShopifyService: PaySessionDelegate {
    func paySession(_ paySession: PaySession, didRequestShippingRatesFor address: PayPostalAddress, checkout: PayCheckout, provide: @escaping (PayCheckout?, [PayShippingRate]) -> Void) {
        print("Apple Pay: Providing shipping rates...")

        // Update the checkout with an incomplete address. Full address will be given to us after authorisation.
        updateAddress(Address(address), checkoutID: GraphQL.ID(rawValue: checkout.id), waitForShippingRates: true)
            .sink { completion in
                switch completion {
                case .failure(let error):
                    print("Apple Pay: Failed to update shipping address", error)
                    provide(nil, [])
                case .finished:
                    break
                }
            } receiveValue: { checkout in
                let payCheckout = checkout.payCheckout
                let payShippingRates = checkout.availableShippingRates.map { $0.payShippingRate }
                provide(payCheckout, payShippingRates)
            }
            .store(in: &subscriptions)
    }
    
    // WARNING:
    // This method is only called for checkouts that DON'T require shipping
    func paySession(_ paySession: PaySession, didUpdateShippingAddress address: PayPostalAddress, checkout: PayCheckout, provide: @escaping (PayCheckout?) -> Void) {
        print("Apple Pay: Did update shipping address...")
        provide(nil)
    }
    
    func paySession(_ paySession: PaySession, didSelectShippingRate shippingRate: PayShippingRate, checkout: PayCheckout, provide: @escaping (PayCheckout?) -> Void) {
        print("Apple Pay: Updating shipping rates...")
        
        updateShippingRate(handle: shippingRate.handle, checkoutID: GraphQL.ID(rawValue: checkout.id))
            .sink { completion in
                switch completion {
                case .failure(let error):
                    print("Apple Pay: Failed to update shipping rate", error)
                    provide(nil)
                case .finished:
                    break
                }
            } receiveValue: { checkout in
                let payCheckout = checkout.payCheckout
                provide(payCheckout)
            }
            .store(in: &subscriptions)
    }
    
    func paySession(_ paySession: PaySession, didAuthorizePayment authorization: PayAuthorization, checkout: PayCheckout, completeTransaction: @escaping (PaySession.TransactionStatus) -> Void) {
        print("Apple Pay: Authorization granted, proceeding to checkout")
        
        guard let email = authorization.shippingAddress.email else {
            print("No email provided")
            completeTransaction(.failure)
            return
        }
        
        guard let currencyCode = Storefront.CurrencyCode(rawValue: checkout.currencyCode) else {
            print("Apple Pay: Invalid currency", checkout.currencyCode)
            completeTransaction(.failure)
            return
        }
        
        let address = Address(authorization.shippingAddress)
        
        let payment: Storefront.TokenizedPaymentInputV3 = .create(
            paymentAmount: .create(amount: checkout.paymentDue, currencyCode: currencyCode),
            idempotencyKey: paySession.identifier,
            billingAddress: address.mutationInput,
            paymentData: authorization.token,
            type: .applePay,
            test: .value(testApplePayPayments)
        )
        
        let checkoutID = GraphQL.ID(rawValue: checkout.id)
        
        updateAddress(address, checkoutID: checkoutID, waitForShippingRates: false)
            .zip(updateEmail(email: email, checkoutID: checkoutID))
            .flatMap { [unowned self] _, _ in
                self.completeWithTokenizedPayment(payment, checkoutID: checkoutID)
            }
            .sink { [unowned self] completion in
                print("Apple Pay: finished", completion)
                switch completion {
                case .finished:
                    completeTransaction(.success)
                    self.paySessionPublisher?.send(completion: .finished)
                case .failure:
                    completeTransaction(.failure)
                    self.paySessionPublisher?.send(completion: .failure(ShopifyError.applePayFailed))
                }
                
                self.paySessionPublisher = nil
            } receiveValue: { [unowned self] checkout in
                print("Apple Pay: Finished with checkout", checkout)
                self.paySessionPublisher?.send(checkout)
            }
            .store(in: &subscriptions)
    }
    
    func paySessionDidFinish(_ paySession: PaySession) {
        cancelTasks()
        self.paySession = nil
        self.paySessionPublisher?.send(completion: .failure(ShopifyError.applePayFailed))
    }
}
