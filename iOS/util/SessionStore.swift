//
//  SessionStore.swift
//  Render Tracker
//
//  Created by Oren Azad on 6/2/21.
//

import Foundation
import FirebaseAuth
import FirebaseMessaging
import FirebaseDatabase
import Purchases


struct User {
    var uid: String
    var email: String
}

class SessionStore: ObservableObject {
    
    @Published var session: User?
    @Published var isAnon: Bool = true
    @Published var isAfterEffects: Bool = false
    var handle: AuthStateDidChangeListenerHandle?
    var IDhandle: IDTokenDidChangeListenerHandle?
    let authRef = Auth.auth()
    
    
    //Start the Authorization Listener
    func listen() {
        handle = authRef.addStateDidChangeListener({(auth, user) in
            if let user = user {
                // identify Purchases with new Firebase user
                Purchases.shared.identify(user.uid, { (info, error) in
                    if let e = error {
                        print("Sign in error: \(e.localizedDescription)")
                    } else {
                        print("User \(user.uid) signed in")
                        self.isAnon = false;
                        self.session = User(uid: user.uid, email: user.email!)
                    }
                })
                let metadataRef = Database.database().reference().ref.child("/metadata/" + user.uid + "/refreshTime")
                let metadataHandle = metadataRef.observe(.value, with: { snapshot in
                    user.getIDTokenForcingRefresh(true) { idToken, error in
                      if let error = error {
                        // Handle error
                        print(error)
                        return;
                      }
                        // Do something with Token
                        print("new token got")
                    }
                })
                
                
            }
            else{
                self.isAnon = true
                self.session = nil
                Purchases.shared.reset()
                print("No User Found")
            }
        })
        
        IDhandle = authRef.addIDTokenDidChangeListener({(auth, user) in
            print("ID TOKEN CALLED")
            if let user = user {
                UserModel().refreshStatus()
                user.getIDTokenResult(completion: { (result, error) in
                    guard let aftereffects = result?.claims["aftereffects"] as? NSNumber else {
                        self.isAfterEffects = false;
                        print("Exited Early")
                    return
                  }
                  if aftereffects.boolValue {
                    if !self.isAfterEffects {
                        self.isAfterEffects = true;
                    }
                    print("ID Token Listener User has Claimed")
                  } else {
                    if self.isAfterEffects {
                        self.isAfterEffects = false;
                    }
                    print("ID Token Listener, User has No claim!")
                  }
                })
            }
        })
    }
    
    
    // Sign Up the User, then add their FCM token to the database.
    func signUp(email: String, password: String) {
        authRef.createUser(withEmail: email, password: password)
        Messaging.messaging().token { fcmToken, error in
            if let error = error {
                print("Error fetching FCM Registration token: \(error)")
            } else if let fcmToken = fcmToken {
                //upload token ID right here
                guard let useruid = (Auth.auth().currentUser?.uid) else { return  }
                let notificationReference = Database.database().reference().ref.child("/utils/" + useruid + "/notificationTokens/" + fcmToken)
                notificationReference.setValue("true")
            }
        }
    }
    
    // Sign In the User, then add their FCM token to the database.
    func signIn(email: String, password: String) {
        authRef.signIn(withEmail: email, password: password) {_,_ in
            Messaging.messaging().token { fcmToken, error in
                if let error = error {
                    print("Error fetching FCM Registration token: \(error)")
                } else if let fcmToken = fcmToken {
                    //upload token ID right here
                    guard let useruid = (Auth.auth().currentUser?.uid) else { return  }
                    let notificationReference = Database.database().reference().ref.child("/utils/" + useruid + "/notificationTokens/" + fcmToken)
                    notificationReference.setValue("true")
                }
            }
        }
    }
    
    // Sign Out the User, then remove their FCM token from the database.
    func signOut(){
        Messaging.messaging().token { fcmToken, error in
            if let error = error {
                print("Error fetching FCM Registration token: \(error)")
                do {
                    try self.authRef.signOut()
                    self.session = nil
                    self.isAnon = true
                }
                catch {
                }
            } else if let fcmToken = fcmToken {
                //remove token ID right here
                guard let useruid = (Auth.auth().currentUser?.uid) else { return  }
                let notificationReference = Database.database().reference().ref.child("/utils/" + useruid + "/notificationTokens/" + fcmToken)
                notificationReference.setValue(nil)
                do {
                    try self.authRef.signOut()
                    self.session = nil
                    self.isAnon = true
                }
                catch {
                }
            }
        }
    }
    
    // Unbind the Authorization Listener.
    func unbind () {
        if let handle = handle {
            authRef.removeStateDidChangeListener(handle)
        }
    }
}
