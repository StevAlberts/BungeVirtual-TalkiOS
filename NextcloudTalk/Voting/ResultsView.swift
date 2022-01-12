//
//  ResultsView.swift
//  NextcloudTalk
//
//  Created by StevalbertS on 06/01/2022.
//

import SwiftUI

@available(iOS 14.0, *)
struct ResultsView: View {
    var body: some View {
        
        VStack(spacing:70){
            
            VStack{
                Text("Voting Question?")
                    .fontWeight(.bold)
                
                Text("Closed on Thursday, January 3, 2022 5:04 PM")
                    .foregroundColor(Color.red)
                    .multilineTextAlignment(.center)

            }.padding()
            
            VStack{
                HStack {
                           
                    Text("YES")

                    Spacer()
                    
                    Text("67%")
                        .padding()
                    Text("2")

                }
                
                HStack {
                           
                    Text("NO")

                    Spacer()
                    
                    Text("33%")
                        .padding()
                    Text("1")

                }
                
                HStack {
                           
                    Text("ABSTAIN")

                    Spacer()
                    
                    Text("0%")
                        .padding()
                    Text("0")

                }
            }
                        
            VStack{
                Text("TOTAL VOTES:  100%")
                Text("Members who have voted: 3")
                    .padding()
//                Text("Total verified voters: 2")
            }

        }.padding()
    
    }
}

@available(iOS 14.0, *)
struct ResultsView_Previews: PreviewProvider {
    static var previews: some View {
        ResultsView()
    }
}
