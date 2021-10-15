//
//  PurchaseService.swift
//  Render Tracker
//
//  Created by Oren Azad on 6/16/21.
//

import Foundation
import Purchases

class PurchaseService {
    
    static func purchase(productId: String?, successfulPurchase:@escaping () -> Void) {
        
        guard productId != nil else {
            return
        }
        
        Purchases.shared.products([productId!]) { (products) in
            if !products.isEmpty {
                let skProduct = products[0]
                Purchases.shared.purchaseProduct(skProduct) { transaction, purchaserInfo, error, userCancelled in
                    if purchaserInfo?.entitlements.all["aftereffects"]?.isActive == true {
                        successfulPurchase()
                    }
                }
            }
        }
    }
}
