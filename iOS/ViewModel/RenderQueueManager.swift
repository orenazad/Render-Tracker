//
//  RenderQueueManager.swift
//  Render Tracker
//
//  Created by Oren Azad on 6/2/21.
//

import Foundation
import FirebaseDatabase
import FirebaseAuth



class RenderQueueManager: ObservableObject {
    @Published var compName = "No Project Open"
    lazy var compRef: DatabaseReference = Database.database().reference().ref.child("/utils/" + (Auth.auth().currentUser?.uid)! + "/ProjectName")
    var compHandle: DatabaseHandle?
    lazy var buttonRef: DatabaseReference = Database.database().reference().ref.child("/utils/" + (Auth.auth().currentUser?.uid)!)
    
    func startProjectNameListener() {
        compHandle = compRef.observe(.value, with: { snapshot in
            if let value = snapshot.value as? String{
                self.compName = value
                print("Started Listening for the project name!")
            }
        })
    }
    
    func stopProjectNameListener() {
        print("Stopped Listening for Project Name")
        if compHandle != nil {
            compRef.removeObserver(withHandle: compHandle!)
        }
    }
    
    func startRender() {
        buttonRef.updateChildValues(["RenderButton": 1])
    }
    
    func clearQueue() {
        buttonRef.updateChildValues(["ClearButton": 1])
    }
}

