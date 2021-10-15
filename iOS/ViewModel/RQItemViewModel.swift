//
//  RQItemViewModel.swift
//  Render Tracker
//
//  Created by Oren Azad on 6/2/21.
//

import Foundation
import FirebaseDatabase
import FirebaseAuth

class RQItemViewModel: ObservableObject {
    
    @Published var rqItems = [RQItem]()
    
    var uidRef: DatabaseReference = Database.database().reference().ref.child("/users/" + (Auth.auth().currentUser?.uid)! + "/")
    var userHandle: DatabaseHandle?
    
    func startRQItemListener() {
        userHandle = uidRef.observe(.value) { snapshot in
            self.rqItems = []
            let enumator = snapshot.children
            while let rest = enumator.nextObject() as? DataSnapshot {
                let dict = rest.value as? [String : AnyObject] ?? [:]
                let rqtest = RQItem(compName: dict["CompName"] as! String, renderStatus: dict["RenderStatus"] as! String)
                self.rqItems.append(rqtest)
            }
        }
    }
    
    func stopRQItemListener() {
        if userHandle != nil {
            uidRef.removeObserver(withHandle: userHandle!)
        }
    }
}
