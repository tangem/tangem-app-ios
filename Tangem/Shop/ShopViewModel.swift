//
//  ShopViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import MobileBuySDK
import SwiftUI

class ShopViewModel: ViewModel, ObservableObject {
    enum Bundle: String, CaseIterable, Identifiable {
        case twoCards, threeCards

        var id: Self { self }

        var sku: String {
            switch self {
            case .twoCards:
                return "TG115x2"
            case .threeCards:
                return "TG115x3"
            }
        }
    }
    
    weak var navigation: NavigationCoordinator!
    weak var assembly: Assembly!
    weak var shopifyService: ShopifyService!
    
    var bag = Set<AnyCancellable>()
    
    // MARK: - Input
    @Published var selectedBundle: Bundle = .threeCards
    @Published var discountCode = ""
    @Published var canUseApplePay = true
    @Published var webCheckoutUrl: URL?
    @Published var showingWebCheckout = false
    
    // MARK: - Output
    @Published var webShopUrl: URL?
    
    @Published var checkingDiscountCode = false
    @Published var showingThirdCard = true
    @Published var loadingProducts = false
    @Published var totalAmountWithoutDiscount: String? = nil
    @Published var totalAmount = ""
    @Published var pollingForOrder = false
    @Published var order: Order?
    
    private var shopifyProductVariants: [ProductVariant] = []
    private var currentVariantID: GraphQL.ID = GraphQL.ID(rawValue: "")
    private var checkoutByVariantID: [GraphQL.ID: Checkout] = [:]
    private var initialized = false
    
    init() {
        if Locale.current.regionCode == "RU" {
            webShopUrl = URL(string: "https://mv.tangem.com")
        }
    }
    
    func didAppear() {
        showingWebCheckout = false
        
        guard !initialized else {
            return
        }
        
        initialized = true
        
        canUseApplePay = shopifyService.canUseApplePay()
        
        $selectedBundle
            .sink { [unowned self] newBundle in
                self.didSelectBundle(newBundle)
            }
            .store(in: &bag)

        $showingWebCheckout
            .dropFirst()
            .removeDuplicates()
            .sink { [unowned self] showingWebCheckout in
                if !showingWebCheckout {
                    self.didCloseWebCheckout()
                }
            }
            .store(in: &bag)
        
        fetchProduct()
    }
    
    func didEnterDiscountCode() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { //Fix iOS13 keyboard layout glitch
            self.setDiscountCode(self.discountCode.isEmpty ? nil : self.discountCode)
        }
    }
    
    func openApplePayCheckout() {
        guard let checkoutID = checkoutByVariantID[currentVariantID]?.id else {
            return
        }
        
        shopifyService
            .startApplePaySession(checkoutID: checkoutID)
            .flatMap { [unowned self] _ -> AnyPublisher<Checkout, Error> in
                self.pollingForOrder = true
                return self.shopifyService.checkout(pollUntilOrder: true, checkoutID: checkoutID)
            }
            .sink { completion in
                print("Finished Apple Pay session", completion)
                self.pollingForOrder = false
            } receiveValue: { [unowned self] checkout in
                print("Checkout after Apple Pay session", checkout)
                if let order = checkout.order {
                    self.didPlaceOrder(order)
                }
            }
            .store(in: &bag)
    }
    
    func openWebCheckout() {
        guard let checkoutID = checkoutByVariantID[currentVariantID]?.id else {
            return
        }
        
        // Checking order ID
        shopifyService.checkout(pollUntilOrder: false, checkoutID: checkoutID)
            .flatMap { [unowned self] checkout -> AnyPublisher<Checkout, Error> in
                self.webCheckoutUrl = checkout.webUrl
                self.showingWebCheckout = true
                
                return self.shopifyService.checkout(pollUntilOrder: true, checkoutID: checkoutID)
            }
            .sink { _ in
                
            } receiveValue: { [unowned self] checkout in
                if let order = checkout.order {
                    self.didPlaceOrder(order)
                }
                self.showingWebCheckout = false
            }
            .store(in: &bag)
    }
    
    private func fetchProduct() {
        loadingProducts = true
        shopifyService
            .products(collectionTitleFilter: nil)
            .sink { completion in
                
            } receiveValue: { [unowned self] collections in
                // There can be multiple variants with the same SKU and the same ID along multiple products.
                let allVariants: [ProductVariant] = collections.reduce([]) { partialResult, collection in
                    let products = collection.products
                    let variants = products.reduce([]) {
                        return $0 + $1.variants
                    }
                    return partialResult + variants
                }
                
                let skusToDisplay = Bundle.allCases.map { $0.sku }
                let variants = skusToDisplay.compactMap { skuToDisplay in
                    allVariants.first {
                        $0.sku == skuToDisplay
                    }
                }
                
                guard variants.count == skusToDisplay.count else {
                    return
                }

                self.loadingProducts = false
                self.shopifyProductVariants = variants
                self.didSelectBundle(self.selectedBundle)
            }
            .store(in: &bag)
    }
    
    private func didSelectBundle(_ bundle: Bundle) {
        withAnimation(.easeOut(duration: 0.25)) {
            showingThirdCard = (bundle == .threeCards)
        }
        
        let sku = bundle.sku
        guard let variant = shopifyProductVariants.first(where: {
            $0.sku == sku
        }) else {
            return
        }
        
        self.currentVariantID = variant.id
        updatePrice()
        createCheckouts()
    }
    
    private func didCloseWebCheckout() {
        shopifyService.cancelTasks()
        if order == nil {
            /*
                HACK:
                After web checkout was displayed it becomes impossible
                to validate a partial address on the Shopify side.
                Thus Apple Pay becomes unusable. Re-create the checkout as a workaround.
            */
            checkoutByVariantID = [:]
            createCheckouts()
        }
    }
    
    private func didPlaceOrder(_ order: Order) {
        self.order = order
        Analytics.logShopifyOrder(order)
    }
    
    private func createCheckouts() {
        // Create a checkout for each product so that we can switch between them immediately.
        // The same logic is behind applying discount codes.
        shopifyProductVariants.forEach {
            createCheckout(variantID: $0.id)
        }
    }
    
    private func createCheckout(variantID: GraphQL.ID) {
        let checkoutID = checkoutByVariantID[variantID]?.id
        guard checkoutID == nil else {
            return
        }
        
        let lineItems: [CheckoutLineItem] = [.checkoutInput(variantID: variantID, quantity: 1)]
        shopifyService
            .createCheckout(checkoutID: checkoutID, lineItems: lineItems)
            .sink { _ in
                
            } receiveValue: { [unowned self] checkout in
                self.checkoutByVariantID[variantID] = checkout
            }
            .store(in: &bag)
    }
    
    private func setDiscountCode(_ discountCode: String?) {
        shopifyProductVariants.forEach {
            setDiscountCode(discountCode, variantID: $0.id)
        }
    }
    
    private func setDiscountCode(_ discountCode: String?, variantID: GraphQL.ID) {
        guard let checkoutID = checkoutByVariantID[variantID]?.id else {
            return
        }
        
        let isCurrentVariantID = (variantID == currentVariantID)
        if isCurrentVariantID && discountCode != nil {
            checkingDiscountCode = true
        }
        
        shopifyService.applyDiscount(discountCode, checkoutID: checkoutID)
            .sink { _ in

            } receiveValue: { [unowned self] checkout in
                if checkout.discount == nil {
                    self.discountCode = ""
                }
                self.checkoutByVariantID[variantID] = checkout
                if isCurrentVariantID {
                    self.updatePrice()
                    self.checkingDiscountCode = false
                }
            }
            .store(in: &bag)
    }
    
    private func moneyFormatter(_ currencyCode: String) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.currencyCode = currencyCode
        return formatter
    }
    
    private func updatePrice() {
        guard let currentVariant = shopifyProductVariants.first(where: {
            $0.id == currentVariantID
        }) else {
            return
        }

        
        let totalAmount: Decimal
        if let checkout = checkoutByVariantID[currentVariantID] {
            totalAmount = checkout.total
        } else{
            totalAmount = currentVariant.amount
        }


        let formatter = moneyFormatter(currentVariant.currencyCode)
        
        self.totalAmount = formatter.string(from: NSDecimalNumber(decimal: totalAmount)) ?? ""
        if let originalAmount = currentVariant.originalAmount {
            self.totalAmountWithoutDiscount = formatter.string(from: NSDecimalNumber(decimal: originalAmount))
        } else {
            self.totalAmountWithoutDiscount = nil
        }
    }
}
