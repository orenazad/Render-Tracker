//
//  ContentView.swift
//  Render Tracker
//
//  Created by Oren Azad on 6/1/21.
//

import SwiftUI



struct ContentView: View {
    
    @ObservedObject var sessionStore = SessionStore()
    @ObservedObject var userModel = UserModel()
    
    init() {
        sessionStore.listen()
        UITabBar.appearance().barTintColor = UIColor(red: 31 / 255, green: 31 / 255, blue: 31 / 255, alpha: 255)
        UITableView.appearance().backgroundColor = UIColor(red: 31 / 255, green: 31 / 255, blue: 31 / 255, alpha: 255)
        UITableView.appearance().backgroundColor = UIColor(red: 31 / 255, green: 31 / 255, blue: 31 / 255, alpha: 255)
    }
    
    var body: some View {
        if (sessionStore.isAnon) {
            LoginView()
                .onDisappear{
                    userModel.refreshStatus()
            }
        }
        else {
            TabView {
                AEHolderView(userModel: userModel, sessionStore: sessionStore)
                    .tabItem {
                        Image("iconAE").renderingMode(.template)
                        Text("After Effects")
                    }
                    .onAppear {
                        userModel.refreshStatus()
                    }
                PremiereProView()
                    .tabItem {
                        Image("iconPR").renderingMode(/*@START_MENU_TOKEN@*/.template/*@END_MENU_TOKEN@*/)
                        Text("Premiere Pro")
                    }
                SettingsView(sessionStore: sessionStore)
                    .tabItem {
                        Image(systemName: "gear").renderingMode(/*@START_MENU_TOKEN@*/.template/*@END_MENU_TOKEN@*/)
                        Text("Settings")
                    }
            }
            .accentColor(.purple)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView()
                .preferredColorScheme(.dark)
        }
    }
}

