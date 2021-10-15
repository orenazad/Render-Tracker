//
//  PremiereProView.swift
//  Render Tracker
//
//  Created by Oren Azad on 6/16/21.
//

import SwiftUI

struct PremiereProView: View {
    var body: some View {
        ZStack {
            Color(red: 31 / 255, green: 31 / 255, blue: 31 / 255).ignoresSafeArea()
            Text("Work In Progress")
                .foregroundColor(Color.gray)
        }
    }
}

struct PremiereProView_Previews: PreviewProvider {
    static var previews: some View {
        PremiereProView()
    }
}
