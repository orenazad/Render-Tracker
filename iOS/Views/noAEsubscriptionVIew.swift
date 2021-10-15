//
//  noAEsubscriptionVIew.swift
//  Render Tracker
//
//  Created by Oren Azad on 6/16/21.
//

import SwiftUI

struct noAEsubscriptionVIew: View {
    
    let testData = [
        RQItem(compName: "Comp 1", renderStatus: "3019"),
        RQItem(compName: "Comp 2", renderStatus: "3019"),
        RQItem(compName: "Comp 4", renderStatus: "3016"),
        RQItem(compName: "Comp 5", renderStatus: "3015"),
        RQItem(compName: "Comp 6", renderStatus: "3015"),
        RQItem(compName: "Comp 8", renderStatus: "3014"),
    ]
    
    @ObservedObject var userModel: UserModel
    
    var body: some View {
        ZStack {
            Color(red: 31 / 255, green: 31 / 255, blue: 31 / 255).ignoresSafeArea()
            VStack(spacing: 0) {
                Text("Subscribe to Render Tracker for After Effects")
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(/*@START_MENU_TOKEN@*/.horizontal/*@END_MENU_TOKEN@*/)
                    .padding(.top,6)
                TabView {
                    VStack(spacing: 0) {
                        RQListView(rqItems: testData)
                        FakeFooterView()
                            .padding(.vertical, 4.0)
                            .background(Color(red: 50 / 255, green: 50 / 255, blue: 50 / 255))
                    }
                    Text("Picture of Push Notifications Here")
                }
                .tabViewStyle(PageTabViewStyle())
                .clipShape(RoundedRectangle(cornerRadius: 25))
                .shadow(color: .black.opacity(0.7), radius: 8, x: /*@START_MENU_TOKEN@*/0.0/*@END_MENU_TOKEN@*/, y: /*@START_MENU_TOKEN@*/0.0/*@END_MENU_TOKEN@*/)
                .padding([.leading, .bottom, .trailing])
                .padding(.top,6)
                Button(action: {
                    userModel.makeAESubscriptionPurchase()
                }, label: {
                    Text("Subscribe").foregroundColor(.white)
                        .fontWeight(.medium)
                        .frame(minWidth: 0, maxWidth: 300, maxHeight: 20)
                        .foregroundColor(Color.white)
                        .padding(/*@START_MENU_TOKEN@*/.all, 8.0/*@END_MENU_TOKEN@*/)
                        .background(Color.purple)
                        .cornerRadius(25)
                })
                Link(destination: URL(string: "https://www.rendertracker.com")!, label: {
                    Text("Render Tracker Support")
                        .foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
                        .padding(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
                })
            }
        }
    }
}





struct FakeFooterView: View {
    
    @State private var showingAlert = false
    
    var body: some View {
        HStack {
            Spacer()
            Button(action: {
            }) {
                Text("Render")
                    .fontWeight(.medium)
                    .frame(minWidth: 0, maxWidth: 300, maxHeight: 20)
                    .foregroundColor(Color.white)
                    .padding(/*@START_MENU_TOKEN@*/.all, 8.0/*@END_MENU_TOKEN@*/)
                    .background(Color.blue)
                    .cornerRadius(20)
            }
            Button(action: {
                showingAlert = true
            }) {
                HStack {
                    Image(systemName: "trash")
                    Text("Clear Queue").lineLimit(1)
                }
                .frame(minWidth: 0, maxWidth: 300, maxHeight: 18.5)
                .foregroundColor(Color.red)
                .padding(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/, 8.0)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.red, style: StrokeStyle(lineWidth: 1.5))
                )
            } .alert(isPresented:$showingAlert) {
                Alert(
                    title: Text("Are you sure you want to clear the Render Queue?"),
                    primaryButton: .destructive(Text("Clear Queue")) {
                    },
                    secondaryButton: .cancel()
                )
            }
            Spacer()
        }
    }
}

struct noAEsubscriptionVIew_Previews: PreviewProvider {
    static var previews: some View {
        noAEsubscriptionVIew(userModel: UserModel())
            .preferredColorScheme(.dark)
    }
}
