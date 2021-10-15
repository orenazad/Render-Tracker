//
//  RenderQueue.swift
//  Render Tracker
//
//  Created by Oren Azad on 6/2/21.
//

import SwiftUI

struct AfterEffectsView: View {
    
    @ObservedObject var sessionStore: SessionStore
    @ObservedObject var projName = RenderQueueManager()
    @ObservedObject var rqItemView = RQItemViewModel()
    
    var body: some View {
        ZStack {
            Color(red: 50 / 255, green: 50 / 255, blue: 50 / 255).ignoresSafeArea()
            VStack {
                HeaderView(projName: projName).padding(.bottom, -1)
                RQListView(rqItems: rqItemView.rqItems)
                FooterView(projName: projName)
                    .padding(.bottom, 6.0)
            }
        }
        .onAppear {
            projName.startProjectNameListener()
            rqItemView.startRQItemListener()
        }.onDisappear {
            projName.stopProjectNameListener()
            rqItemView.stopRQItemListener()
        }
    }
}


struct HeaderView: View {
    @ObservedObject var projName: RenderQueueManager
    var body: some View {
        HStack {
            Text(projName.compName)
                .font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
                .fontWeight(.heavy)
                .foregroundColor(Color.white)
                .lineLimit(1)
                .padding(.top, 6)
                .minimumScaleFactor(0.0001)
            Spacer()
        }
        .padding(.leading)
    }
}

struct FooterView: View {
    
    @ObservedObject var projName: RenderQueueManager
    @State private var showingAlert = false
    
    var body: some View {
        HStack {
            Spacer()
            Button(action: {
                projName.startRender()
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
                .frame(minWidth: 0, maxWidth: 125, maxHeight: 18.5)
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
                        projName.clearQueue()
                    },
                    secondaryButton: .cancel()
                )
            }
            Spacer()
        }
    }
}

struct RQListView: View {
    var rqItems: [RQItem]
    var body: some View {
        
        //If there are no items in the Render Queue, Display a nice message!
        if (rqItems.count == 0) {
            ZStack{
                Rectangle().foregroundColor(Color(red: 31 / 255, green: 31 / 255, blue: 31 / 255))
                VStack(alignment: .center){
                    Spacer()
                    Text("No Items in the Render Queue.")
                        .font(.body)
                        .foregroundColor(Color.gray)
                        .multilineTextAlignment(.center)
                        .padding(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
                    Text("Enjoy the break! You deserve it.")
                        .font(.body)
                        .foregroundColor(Color.gray)
                        .multilineTextAlignment(.center)
                        .padding(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
                    Spacer()
                }
            }
        }
        
        //Items are in the Render Queue! List them.
        else {
            List {
                ForEach(rqItems.indices, id: \.self) { index in
                    RQItemView(index: index + 1, compName: rqItems[index].compName, renderStatus: rqItems[index].renderStatus)
                        .listRowBackground((index  % 2 == 0) ? Color(red: 37 / 255, green: 37 / 255, blue: 37 / 255) : Color(red: 31 / 255, green: 31 / 255, blue: 31 / 255))
                }
            }
        }
    }
}

struct RQItemView: View {
    var index: Int
    var compName: String
    var renderStatus: String
    var body: some View {
        HStack {
            Text(String(index))
                .font(.headline.monospacedDigit())
                .fontWeight(.medium)
                .foregroundColor(Color.gray)
                .padding(.trailing)
            Text(compName)
                .font(.title2.monospacedDigit())
                .fontWeight(.semibold)
                .foregroundColor(Color.white)
                .multilineTextAlignment(.leading)
                .padding(/*@START_MENU_TOKEN@*/[.top, .bottom, .trailing]/*@END_MENU_TOKEN@*/)
            Spacer()
            if (renderStatus == "3012") {
                Text("Paused")
                    .foregroundColor(Color.orange)
            }
            else if (renderStatus == "3013") {
                Text("Needs Output")
                    .foregroundColor(Color.orange)
            }
            else if (renderStatus == "3014") {
                Text("Unqueued")
                    .foregroundColor(Color.orange)
            }
            else if (renderStatus == "3015") {
                Text("Queued")
                    .foregroundColor(Color.blue)
            }
            else if (renderStatus == "3016") {
                Text("Rendering")
                    .foregroundColor(Color.purple)
            }
            else if (renderStatus == "3017") {
                Text("User Stopped")
                    .foregroundColor(Color.red)
            }
            else if (renderStatus == "3018") {
                Text("Error Stopped")
                    .foregroundColor(Color.red)
            }
            
            else if (renderStatus == "3019") {
                Text("Done ✓")
                    .foregroundColor(Color.green)
            }
        }
        .font(/*@START_MENU_TOKEN@*/.title2/*@END_MENU_TOKEN@*/)
    }
}


struct RenderQueue_Previews: PreviewProvider {
    static var previews: some View {
        AfterEffectsView(sessionStore: SessionStore())
            .preferredColorScheme(.dark)
    }
}
