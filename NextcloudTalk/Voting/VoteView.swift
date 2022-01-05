//
//  VoteView.swift
//  NextcloudTalk
//
//  Created by StevalbertS on 30/12/2021.
//

import Foundation
import SwiftUI


@available(iOS 14.0, *)
struct VoteView: View {
    var body: some View {
        NavigationView {
            VStack{
                Button {
                    AuthClass.isValidUer(reasonString: "Voter verification") {(isSuccess, stringValue) in
                        
                        if isSuccess
                        {
                            print("evaluating...... successfully completed")
                        }
                        else
                        {
                            print("evaluating...... failed to recognise user \n reason = \(stringValue?.description ?? "invalid")")
                        }
                        
                    }
                } label: {
                    Text("Click to request OTP")
                        .padding(12)
                }
                .contentShape(Rectangle())
                .padding(.all, 12)
                          .background(Color.yellow)
                          .foregroundColor(Color.black)
                          .cornerRadius(25)
            }
        }
        .navigationTitle("Vote")
        .navigationBarTitleDisplayMode(.inline)
    }
}

@available(iOS 14.0, *)
struct VoteView_Previews: PreviewProvider {
    static var previews: some View {
        VoteView()
    }
}
