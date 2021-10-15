//
//  SettingsView.swift
//  Render Tracker
//
//  Created by Oren Azad on 6/15/21.
//

import SwiftUI

struct SettingsView: View {
    
    @ObservedObject var sessionStore: SessionStore
    
    var body: some View {
        ZStack {
            Color(red: 50 / 255, green: 50 / 255, blue: 50 / 255).ignoresSafeArea()
            VStack {
                settingsHeader().padding(.bottom, -1)
                formView(sessionStore: sessionStore)
            }
        }
    }
}

struct settingsHeader: View {
    var body: some View {
        HStack {
            Text("Settings")
                .font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
                .fontWeight(.heavy)
                .foregroundColor(Color.white)
                .lineLimit(1)
                .padding(.top, 6)
            Spacer()
        }
        .padding(.leading)
    }
}

struct formView: View {
    
    @ObservedObject var sessionStore: SessionStore
    
    var body: some View {
        Form {
            Section(header: Text("Account - " + getEmail(sessionStore: sessionStore)).padding(.top)) {
                Button(action: {
                    sessionStore.signOut()
                }, label: {
                    Text("Sign Out").foregroundColor(.red)
                })
                Button(action: {
                    //TODO: Bring to screen which explains how to cancel your subscription!
                }, label: {
                    Text("Cancel Subscription").foregroundColor(.red)
                })
            }.listRowBackground(Color(red: 50 / 255, green: 50 / 255, blue: 50 / 255))
            
            
            Section(header: Text("Issues")) {
                Text("Report a bug").foregroundColor(.white)
            }.listRowBackground(Color(red: 50 / 255, green: 50 / 255, blue: 50 / 255))
            
            
            Section(header: Text("About")) {
                Button(action: {
                    openAppStore()
                }, label: {
                    Text("Rate Render Tracker").foregroundColor(.white)
                })
                Text("Tip Jar").foregroundColor(.white)
            }.listRowBackground(Color(red: 50 / 255, green: 50 / 255, blue: 50 / 255))
        }
    }
}

func openAppStore() {
    if let url = URL(string: "https://apps.apple.com/us/app/render-tracker/id1572738587"),
       UIApplication.shared.canOpenURL(url){
        UIApplication.shared.open(url, options: [:]) { (opened) in
            if(opened){
                print("App Store Opened")
            }
        }
    } else {
        print("Can't Open URL on Simulator")
    }
}

func getEmail(sessionStore: SessionStore) -> String {
    var email = sessionStore.session?.email
    if email == nil {
        email = "No account signed in."
    }
    return email!;
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(sessionStore: SessionStore())
    }
}
