//
//  MainView.swift
//  NextcloudTalk
//
//  Created by StevalbertS on 06/01/2022.
//

import SwiftUI
import SwiftyJSON

extension Date {
    func adding(hours: Int) -> Date {
        return Calendar.current.date(byAdding: .hour, value: hours, to: self)!
    }
}

@available(iOS 14.0, *)
struct MainView: View {
   
    let api = NCAPIController()
    
    @State var vote:NCVote
    @State var polls = [Poll]()
    @State var showOTPView = false
    @State private var otpCode: String = ""
    @State var otpVerified = false
    @State var poll: Poll?
    @State var loading = false
    
    @State var closeDate: String = ""

    func getPolls() {
        // get user account
        var account = TalkAccount()
        let db = NCDatabaseManager()
        account = db.activeAccount()

        // get polls
        api.getPolls(account) { response, error in
        
//            print("Response..: \(String(describing: response))")
                        
            let pollsArray : NSArray = response?["polls"] as? NSArray ?? []
             
//            print("Polls..: \(String(describing: pollsArray))")
                    
            if response != nil {
                
                self.loading = false
//                self.otpVerified = true

                  pollsArray.forEach { pollJson in
                      let json = JSON(pollJson).rawString()
                      let jsonData = json!.data(using: .utf8)!
                      
                      let poll: Poll = try!  JSONDecoder().decode(Poll.self, from: jsonData)
                       
//                      let polly = try! Poll(data: jsonData)
                      
                      print(poll.title)
                      
                      print(poll.meetingID)
                      
                      print(vote.meetingId!)
                     
                      if poll.meetingID == vote.meetingId {
                          print("======LETS POLL VOTE====")
                          self.otpVerified = true
                          self.poll = poll
                          print("Poll..: \(String(describing: self.poll))")

                      }
                      
                      polls.append(poll)
                 }
                
                print(polls.count)
                
//                if polls.count > 0{
//                    if !otpCode.isEmpty{
//                        self.otpVerified = true
//                    }
//                }
                
            }else{
                print("No results")
            }
            
            
            if(error != nil){
                print("Error: \(String(describing: error))")
            }

        }.resume()
        
        
        print("verifyOTP success")
    }
    
    
    func sendOTP() {
        // get user account
        var account = TalkAccount()
        let db = NCDatabaseManager()
        account = db.activeAccount()

        // send otp
        api.sendOtpSms(forUser: account, otpExpire: vote.openingTime as NSNumber, withPollId: vote.voteId as NSNumber) { response, error in
            
            print("sendOTPResponse..: \(String(describing: response))")
            print("sendOTP success")

            if(error != nil){
                print("sendOtpSmsError: \(String(describing: error))")
            }
            
        }.resume()
        
    }
    
    
    func verifyOTP() {
        // get user account
        var account = TalkAccount()
        let db = NCDatabaseManager()
        account = db.activeAccount()

        // verify otp
        api.verifyOtp(Int(otpCode) as NSNumber?, forUser: account) { response, error in
        
            print("verifyOTPResponse..: \(String(describing: response))")
            print("verifyOTP success")
            
            // get user polls
            self.getPolls()

            if(error != nil){
                print("verifyOTPError: \(String(describing: error))")
            }
            
        }.resume()
         
        
    }
    

    var body: some View {
        
        if !showOTPView {
            
            VStack(spacing:50){
                
                VStack(){
                    Text("Time left to verify")
                    Text("4:56")
                        .fontWeight(.bold).font(.system(size: 20))
                        .padding(8)
                }
                
                TextField("Enter OTP code", text: $otpCode)
                    .padding()
                    .border(Color.green, width: 1)
                    .textContentType(.oneTimeCode)
                    .keyboardType(.numberPad)
                    
                
                if loading {
                    ProgressView()
                        .scaleEffect(2.0)
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    HStack(spacing:50){
                        Button {
                            self.showOTPView = false
                        } label: {
                            Text("Cancel")
                                .padding(12)
                        }
                        .foregroundColor(Color.red)
                        
                        Button {
                            if !otpCode.isEmpty {
                                verifyOTP()
                                self.loading = true
                            }else{
                                print("No OTP entered")
                            }
                        } label: {
                            Text("OK")
                                .padding(12)
                        }
                        .contentShape(Rectangle())
                        .background(Color.green)
                        .foregroundColor(Color.white)
                        .cornerRadius(15)
                    }
                }
                
            }.padding()
            
        } else{
            
            VStack(spacing:50){

                VStack(){
                    Text("Time left to verify")
                    Text("4:56")
                        .fontWeight(.bold).font(.system(size: 20))
                        .padding(8)
                }.onAppear(){
                                      
//                    var secondsRemaining = vote.openingTime;
 
                    Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { (Timer) in

//                        let date = Date().adding(hours: 3)
//                        let now = date.timeIntervalSince1970
//                        let opening = TimeInterval(vote.openingTime)
//
//                        let diff = now - opening
                        
                        
                                       
//                        let expireTime = TimeInterval(poll?.pollExpire ?? Int(now))
//                        let myDate = NSDate(timeIntervalSince1970: diff)
////
//                        let dateFormatter = DateFormatter()
//                        dateFormatter.dateFormat = "mm:ss"
//                        let strDate = dateFormatter.string(from: myDate as Date)
//                        print("Date: \(strDate)")
//
//                        print("\(hour):\(minute):\(second)")
                        
                      
                        
                        

//                        let duration = differenceInSeconds.second
                      
//                        print ("\(String(describing: duration)) seconds")
                           
//                        if secondsRemaining > 0 {
//                            print ("\(String(describing: secondsRemaining)) seconds")
////                            self.closeDate = String(secondsRemaining)
//                        } else {
//                            print("time ended")
//                            Timer.invalidate()
//                        }
                    }
                }

                Button {
                    AuthClass.isValidUer(reasonString: "Voter verification") {(isSuccess, stringValue) in
                        if isSuccess {
                            print("evaluating...... successfully completed")
                        
                            self.sendOTP()
                            self.showOTPView = true
                            
                        } else {
                            print("evaluating...... failed to recognise user \n reason = \(stringValue?.description ?? "invalid")")
                        }

                    }
                } label: { 
                    Text("Click to request OTP")
                        .padding(12)
                }
                .contentShape(Rectangle())
                .background(Color.yellow)
                .foregroundColor(Color.black)
                .cornerRadius(15)
 
            }
        }
         
        if poll != nil {
            NavigationLink(destination: VotingView(poll: self.poll!),
               isActive: self.$otpVerified) {
                 EmptyView()
            }.hidden().onDisappear{
                self.showOTPView = false
                self.otpCode = ""
            }
        }
    }
}

@available(iOS 14.0, *)
struct MainView_Previews: PreviewProvider {
    static var previews: some View {
//        MainView()
        EmptyView()
    }
}
