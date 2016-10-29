//
// IGIAPManager.swift
// Aloha
//
// Created by IvanGao on 10/24/16.
// Copyright © 2016 IvanGao. All rights reserved.
//

import Foundation
import StoreKit

protocol IGIAPManagerDelegate: NSObjectProtocol {
    
    func iapProductionListRequestSuccess()
    func iapProductionListRequestFailed()
    func iapProductionPurchaseSuccess(paymentTransactionId: String, receiptString: String)
    func iapProductionPurchaseFailed(productIdentifier: String, error: NSError?)
}

class IGIAPManager: NSObject {
    static let sharedInstance = IGIAPManager()
    weak var delegate: IGIAPManagerDelegate?
    private(set) var productList: [SKProduct] = []
    
    static func addIAPTransactionObserver() {
        SKPaymentQueue.default().add(sharedInstance)
    }
    
    static func removeIAPTransactionObserver() {
        SKPaymentQueue.default().remove(sharedInstance)
    }
    
    static func purchaseProductWithIapId(iapId: String) {
        let products = sharedInstance.productList.filter { $0.productIdentifier == iapId }
        guard let product = products.first else { return }
        let payment = SKMutablePayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
    
    static func closeSuccessTransaction(transactionIdentifier: String) {
        SKPaymentQueue.default().transactions.forEach { paymentTransaction in
            guard paymentTransaction.transactionIdentifier == transactionIdentifier else { return }
            SKPaymentQueue.default().finishTransaction(paymentTransaction)
        }
    }
    
    static func closeFailedTransaction(productIdentifier: String) {
        SKPaymentQueue.default().transactions.forEach { paymentTransaction in
            guard paymentTransaction.payment.productIdentifier == productIdentifier else { return }
            SKPaymentQueue.default().finishTransaction(paymentTransaction)
        }
    }
}

extension IGIAPManager: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        transactions.forEach { paymentTransaction in
            switch paymentTransaction.transactionState {
            case .failed:
                self.delegate?.iapProductionPurchaseFailed(productIdentifier: paymentTransaction.payment.productIdentifier, error: paymentTransaction.error as NSError?)
            case .purchased, .restored:
                if let url = Bundle.main.appStoreReceiptURL,
                    let data = NSData(contentsOf: url) {
                    let receiptString = data.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
                    self.delegate?.iapProductionPurchaseSuccess(paymentTransactionId: paymentTransaction.transactionIdentifier!, receiptString: receiptString)
                }
            case .purchasing, .deferred:
                break
            }
        }
    }
}

extension IGIAPManager: SKProductsRequestDelegate {
    
    static func productRequest(iapIds: [String]) {
        let request = SKProductsRequest(productIdentifiers: Set(iapIds))
        request.delegate = sharedInstance
        request.start()
    }
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        guard response.products.count > 0 else {
            self.delegate?.iapProductionListRequestFailed()
            return
        }
        self.delegate?.iapProductionListRequestSuccess()
    }
}
