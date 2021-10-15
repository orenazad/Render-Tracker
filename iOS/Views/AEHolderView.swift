//
//  AEHolderView.swift
//  Render Tracker
//
//  Created by Oren Azad on 6/17/21.
//

import SwiftUI
import FirebaseAuth

struct AEHolderView: View {
    
    @ObservedObject var userModel: UserModel
    @ObservedObject var sessionStore: SessionStore
    
    var body: some View {
        
        if (userModel.afterEffectsSubscription == false || !sessionStore.isAfterEffects) {
            noAEsubscriptionVIew(userModel: userModel)
        }
        
        else if (userModel.afterEffectsSubscription == true && !sessionStore.isAnon && sessionStore.isAfterEffects) {
            AfterEffectsView(sessionStore: sessionStore)
        }
        
    }
}

//struct AEHolderView_Previews: PreviewProvider {
//    static var previews: some View {
//        AEHolderView()
//    }
//}
