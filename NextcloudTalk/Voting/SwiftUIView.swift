//
//  VotingView.swift
//  NextcloudTalk
//
//  Created by StevalbertS on 03/01/2022.
//

import SwiftUI


@available(iOS 14.0, *)
struct SwiftUIView: View {
    
    @State var vote = NCVote()
    let api = NCAPIController()

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
                    let otp = Int(code) ?? 0
                    print(otp)

//                    var account = TalkAccount()
//                    let db = NCDatabaseManager()
//                    account = db.activeAccount()
                                    
           
//                    api.verifyOtp(otp as NSNumber, forUser: account) { response, error in
//
//                        print("verifyOtp Response: \(String(describing: response))")
//
////                        self.showVotingView = true
//
//                        api.getPolls(account) { response, error in
//                            print("getPolls Response: \(String(describing: response))")
//                            if(error != nil){
//                                print("getPolls....Error: \(String(describing: error))")
//                            }
//                        }.resume()
//
//                        if(error != nil){
//                            print("verifyOtp....Error: \(String(describing: error))")
//                        }
//
//                    }.resume()
                    
                    
                }
                
//                NavigationLink(
//                    destination: VotingView()
//                ) {
//                    Text("Do Something")
//                }.padding()
                
                
            }
            .padding()
            
        // voting view
        } else if showVotingView {
//            VotingView()
            
        // verification view
        } else {
            VStack{
                
//                Text("\(vote.title)")
                
                Button {
                    AuthClass.isValidUer(reasonString: "Voter verification") {(isSuccess, stringValue) in
                        if isSuccess
                        {
                            print("evaluating...... successfully completed")
                        
                            var account = TalkAccount()
                            let db = NCDatabaseManager()
                            account = db.activeAccount()
                            
                            print("Account.....:\(account.userId)")
                            
//                            api.sendOtpSms(forUser: account, otpExpire: vote.openingTime as NSNumber, withPollId: vote.voteId as NSNumber) { response, error in
//
//                                print("OTP Response: \(String(describing: response))")
//
//                                self.showSmsCodeView = true
//
//                                if(error != nil){
//                                    print("Error: \(String(describing: error))")
//                                }
//
//                            }.resume()
                        
                            
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
            
        }
    }
}


// Vote casting view
@available(iOS 14.0, *)
struct VotingsView: View {
    
    @State var options = ""

    var body: some View {
        Text("Casting, World!")
        
        VStack{
            RadioButtonField(
                            id: "yes",
                            label: "YES",
//                            color:.black,
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
//                            color:.black,
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
//                color:.black,
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
struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        SwiftUIView()
    }
}
