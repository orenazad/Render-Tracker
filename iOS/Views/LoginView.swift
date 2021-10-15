//
//  Login.swift
//  Render Tracker
//
//  Created by Oren Azad on 6/2/21.
//

import SwiftUI

struct LoginView: View {
    @State var email = ""
    @State var password = ""
    @ObservedObject var sessionStore = SessionStore()
    
    
    var body: some View {
        NavigationView {
            VStack {
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button(action: {
                    sessionStore.signUp(email: email, password: password)
                }, label: {
                    Text("Sign Up")
                })
                Button(action: {
                    sessionStore.signIn(email: email, password: password)
                }, label: {
                    Text("Sign In")
                })
            }
            .padding(.horizontal)
            .navigationBarTitle("Welcome")
        }
    }
}

struct Login_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
