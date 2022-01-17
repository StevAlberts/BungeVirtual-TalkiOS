//
//  CommentsView.swift
//  NextcloudTalk
//
//  Created by StevalbertS on 17/01/2022.
//

import SwiftUI

struct CommentsView: View {
    @State var message: String = ""
    
    func sendMessage() {
            print("Message: \(message)")
        }
    
    var body: some View {
            
        
        VStack {
           List {
//               ForEach(chatHelper.realTimeMessages, id: \.self) { msg in
//                  MessageView(checkedMessage: msg)
//                }
               
               
               HStack(alignment: .bottom, spacing: 10) {
                 Image("bunge")
                           .resizable()
                           .frame(width: 40, height: 40, alignment: .center)
                           .cornerRadius(20)
                   
                   Text("Internet inatupanga Internet inatupanga Internet inatupanga")
                       .padding(10)
                       .cornerRadius(10)
                   
                   
                   Button {
                       print("Delete button was tapped")
                   } label: {
                       Image(systemName: "delete-forever")
                   }
                   
              }
           }
            
           HStack {
               TextField("Message...", text: $message)
                  .textFieldStyle(RoundedBorderTextFieldStyle())
                  .frame(minHeight: CGFloat(30))
                Button(action: sendMessage) {
                    Text("Send")
                 }
            }.frame(minHeight: CGFloat(20)).padding()
        }
        .navigationTitle("Comments")
        .onAppear {
            print("Helloz")
        }
    }
}

struct CommentsView_Previews: PreviewProvider {
    static var previews: some View {
        CommentsView()
    }
}

