//
//  VotingView.swift
//  NextcloudTalk
//
//  Created by StevalbertS on 03/01/2022.
//

import SwiftUI


@available(iOS 14.0, *)
struct MainView: View {
    
    @State var vote = NCVote()
    
    @State var showSmsCodeView = false
    @State var showVotingView = false
    @State private var code: String = ""

    // Main view
    var body: some View {
        
        // otp sms view
        if showSmsCodeView {
            VStack{
                
                Text("Time left to verify: 35:19")
                
                Text("Number of voters: 0")
                
                TextField("Enter OTP code", text: $code)
                    .padding()
                    .border(Color.green, width: 1)

                Button("OK") {
                    print(code)
                    
                    if code != "yes" {
                        print("YES: \(code)")
                        self.showVotingView = true
                    }
                }
                
                
            }
            .padding()
            
        // voting view
        } else if showVotingView {
            VotingView()
            
        // verification view
        } else {
            VStack{
                
//                Text("\(vote.title)")
                
                Button {
                    AuthClass.isValidUer(reasonString: "Voter verification") {(isSuccess, stringValue) in
                        if isSuccess
                        {
                            print("evaluating...... successfully completed")
                            
                            self.showSmsCodeView = true

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
            .padding()
            .onAppear(){
                print("MainView.....:\(vote.title)")
            }
        }
    }
}


// Vote casting view
@available(iOS 13.0.0, *)
struct VotingView: View {
    
    @State var options = ""

    var body: some View {
        Text("Casting, World!")
        
        VStack{
            RadioButtonField(
                            id: "yes",
                            label: "YES",
                            color:.black,
                            bgColor: $options.wrappedValue == "yes" ? .green : .red,
                            isMarked: $options.wrappedValue == "yes" ? true : false,
                            callback: { selected in
                                self.options = selected
                                print("Selected Gender is: \(selected)")
                            }
            ).padding()
            
            RadioButtonField(
                            id: "no",
                            label: "NO",
                            color:.black,
                            bgColor: $options.wrappedValue == "no" ? .green : .red,
                            isMarked: $options.wrappedValue == "no" ? true : false,
                            callback: { selected in
                                self.options = selected
                                print("Selected Gender is: \(selected)")
                            }
            ).padding()
            
            RadioButtonField(
                id: "abstain",
                label: "ABSTAIN",
                color:.black,
                bgColor: $options.wrappedValue == "abstain" ? .green : .red,
                isMarked: $options.wrappedValue == "abstain" ? true : false,
                callback: { selected in
                    self.options = selected
                    print("Selected Gender is: \(selected)")
                }
            ).padding()
        }
    }
}



@available(iOS 14.0, *)
struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
