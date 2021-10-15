//
//  UserModel.swift
//  Render Tracker
//
//  Created by Oren Azad on 6/16/21.
//

import Foundation
import Purchases


class UserModel: ObservableObject {
    
    @Published var afterEffectsSubscription = false;
    @Published var premiereProSubscription = false; //Not currently used.
    
    init() {
        Purchases.shared.purchaserInfo { info, error in
            if info?.entitlements["aftereffects"]?.isActive == true {
                self.afterEffectsSubscription = true;
            }
        }
    }
    
    func makeAESubscriptionPurchase() {
        PurchaseService.purchase(productId: "rt_99_1m") {
            self.afterEffectsSubscription = true;
        }
    }
    
    func refreshStatus() {
        Purchases.shared.purchaserInfo { info, error in
            if info?.entitlements["aftereffects"]?.isActive == true {
                if self.afterEffectsSubscription != true {
                    self.afterEffectsSubscription = true;
                }
                else {
                    return;
                }
            }
            else {
                if self.afterEffectsSubscription != false {
                    self.afterEffectsSubscription = false;
                }
                else {
                    return;
                }
            }
        }
    }
}
