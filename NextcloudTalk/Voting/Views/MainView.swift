//
//  MainView.swift
//  NextcloudTalk
//
//  Created by StevalbertS on 06/01/2022.
//

import SwiftUI
import SwiftyJSON
import UIKit
import Foundation

extension UIAlertController {
    class func alert(title:String, msg:String, target: UIViewController) {
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default) {
        (result: UIAlertAction) -> Void in
        })
        target.present(alert, animated: true, completion: nil)
    }
}

extension Date {
    func adding(hours: Int) -> Date {
        return Calendar.current.date(byAdding: .hour, value: hours, to: self)!
    }
    static func -(recent: Date, previous: Date) -> (month: Int?, day: Int?, hour: Int?, minute: Int?, second: Int?) {
           let day = Calendar.current.dateComponents([.day], from: previous, to: recent).day
           let month = Calendar.current.dateComponents([.month], from: previous, to: recent).month
           let hour = Calendar.current.dateComponents([.hour], from: previous, to: recent).hour
           let minute = Calendar.current.dateComponents([.minute], from: previous, to: recent).minute
           let second = Calendar.current.dateComponents([.second], from: previous, to: recent).second

           return (month: month, day: day, hour: hour, minute: minute, second: second)
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
    @State private var showingAlert = false
    @State private var currentButton: Int? = nil
    @State var closeDate: String = ""

    func getPolls() {
        // get user account
        var account = TalkAccount()
        let db = NCDatabaseManager()
        account = db.activeAccount()

        // get polls
        api.getPolls(account) { response, error in
        
//            print("Response.getPolls.: \(String(describing: response))")
                        
            let pollsArray : NSArray = response?["polls"] as? NSArray ?? []
             
//            print("Polls..: \(String(describing: pollsArray))")
                    
            if response != nil {
                
                  pollsArray.forEach { pollJson in
                      let json = JSON(pollJson).rawString()
                      let jsonData = json!.data(using: .utf8)!
                      
//                      print("JSON...:\(pollJson)")
                      
                      let poll: Poll = try!  JSONDecoder().decode(Poll.self, from: jsonData)
                       
//                      let polly = try! Poll(data: jsonData)
//                      print(poll.title)
//                      print(poll.meetingID)
//                      print(vote.meetingId!)
                     
                      if poll.pollID == vote.voteId {
                          self.loading = false
//                          print("======LETS POLL VOTE====")
                          self.poll = poll
//                          print("Poll..: \(String(describing: self.poll))")
                          self.otpVerified = true
                          
                      }
                      
                      polls.append(poll)
                 }
                
//                print(polls.count)
                
            }else{
                print("No results")
                
            }
            
            
            if(error != nil){
                print("Error: \(String(describing: error))")
            }

        }.resume()
        
        
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
//        let alert = UIAlertController(title: "Alert", message: "OTP verification failed", preferredStyle: .alert)
//        let ok = UIAlertAction(title: "OK", style: .default, handler: { action in })
//        alert.addAction(ok)
        
        // verify otp
        api.verifyOtp(otpCode, withPollId: vote.voteId as NSNumber, forUser: account) { response, error in

            print("verifyOTPResponse..: \(String(describing: response))")
            print("verifyOTP success")
            self.loading = false
            
            
            // get user polls
            self.getPolls()

            if(error != nil){
                print("verifyOTPError: \(String(describing: error))")
                self.loading = false
                self.showingAlert = true
                print("Verification failed ?????????")
            }
             
        }.resume()
        
        
    }
    

    var body: some View {
        
        if showOTPView {
            
            VStack(spacing:50){
                
                VStack(){
                    Text("Time left to verify")
                    Text("\(closeDate)")
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
                        .alert(isPresented: $showingAlert) {
                            Alert(title: Text("Alert"), message: Text("OTP verification failed."), dismissButton: .default(Text("OK")))
                        }
                    }
                }
                
            }.padding()
            
        } else{
            
            VStack(spacing:50){

                VStack(){
                    Text("Time left to verify")
                    Text("\(closeDate)")
                        .fontWeight(.bold).font(.system(size: 20))
                        .padding(8)
                }.onAppear(){
                    print("Welcome to voting")
                    print("Vote..: \(vote)")
                    let opening = vote.openingTime;
                    Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { (Timer) in
                        let calendar = Calendar.current
                        let now = Date().adding(hours: 3)
                        let date = Date(timeIntervalSince1970: TimeInterval(opening)).adding(hours: 3)
                        let diff = calendar.dateComponents([.hour, .minute, .second], from: now, to: date)
                        if diff.second! >= 0 {
                            let mins = String(format: "%02d", diff.minute!)
                            let secs = String(format: "%02d", diff.second!) // returns "100"
                            self.closeDate = "\(mins):\(secs)"
                        }
//                        self.closeDate = "\(diff.minute!):\(diff.second!)"
//                        print("Left...: \(diff.minute!):\(diff.second!)")
                        // get user polls
                        self.getPolls()
                        
                    }
                }

                if poll == nil {
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
                    
                } else {
                    // navigate if poll is available
                    NavigationLink(destination: VotingView(poll: self.poll!,meetingId: vote.meetingId!), tag: 1, selection: $currentButton) {
                        EmptyView()
                    }
                    Button {
                        self.currentButton = 1 // this activates NavigationLink with specified tag
                    } label: {
                        Text("Open Vote")
                            .foregroundColor(Color.red)
                            .fontWeight(.bold).font(.system(size: 20))
                            .padding(8)
                    }
                }
 
            }
        }
         
        if poll != nil {
            NavigationLink(destination: VotingView(poll: self.poll!,meetingId: vote.meetingId!),
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
