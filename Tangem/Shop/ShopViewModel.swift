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

#warning("[REDACTED_TODO_COMMENT]")

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
    @Published var checkingDiscountCode = false
    @Published var showingThirdCard = true
    @Published var totalAmountWithoutDiscount: String? = nil
    @Published var totalAmount = ""
    @Published var order: Order?
    
    private var shopifyProductVariants: [ProductVariant] = []
    private var currentVariantID: GraphQL.ID = GraphQL.ID(rawValue: "")
    private var checkoutByVariantID: [GraphQL.ID: Checkout] = [:]
    
    func didAppear() {
        self.canUseApplePay = shopifyService.canUseApplePay()
        
        $selectedBundle
            .sink { [weak self] newBundle in
                self?.didSelectBundle(newBundle)
            }
            .store(in: &bag)
        
        $discountCode
            .dropFirst()
            .debounce(for: 1.0, scheduler: RunLoop.main, options: nil)
            .removeDuplicates()
            .sink { [weak self] code in
                self?.setDiscountCode(code.isEmpty ? nil : code)
            }
            .store(in: &bag)

        fetchProduct()
    }
    
    private func fetchProduct() {
        shopifyService
            .products(collectionTitleFilter: nil)
            .sink { completion in
                print(completion)
            } receiveValue: { [weak self] collections in
                guard let self = self else {
                    return
                }
                
                let allProducts: [Product] = collections.reduce([]) { partialResult, collection in
                    return partialResult + collection.products
                }
                
                let walletProduct = allProducts.first { product in
                    let variantSkus = product.variants.compactMap { $0.sku }
                    return variantSkus.contains("TG115x2") && variantSkus.contains("TG115x3")
                }

                guard let walletProduct = walletProduct else {
                    return
                }

                
                self.shopifyProductVariants = walletProduct.variants
                
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
                
            } receiveValue: { [weak self] checkout in
                self?.checkoutByVariantID[variantID] = checkout
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

            } receiveValue: { [weak self] checkout in
                if checkout.discount == nil {
                    self?.discountCode = ""
                }
                self?.checkoutByVariantID[variantID] = checkout
                if isCurrentVariantID {
                    self?.updatePrice()
                    self?.checkingDiscountCode = false
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
    
    func openApplePayCheckout() {
        guard let checkoutID = checkoutByVariantID[currentVariantID]?.id else {
            return
        }
        
        shopifyService
            .startApplePaySession(checkoutID: checkoutID)
            .sink { completion in
                print("Finished Apple Pay session", completion)
            } receiveValue: { [weak self] checkout in
                print("Checkout after Apple Pay session", checkout)
                self?.order = checkout.order
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
                
            } receiveValue: { [weak self] checkout in
                self?.order = checkout.order
                self?.showingWebCheckout = false
            }
            .store(in: &bag)
    }
}
