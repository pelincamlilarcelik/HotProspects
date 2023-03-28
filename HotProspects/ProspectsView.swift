//
//  ProspectsView.swift
//  HotProspects
//
//  Created by Onur Celik on 27.03.2023.
//
import CodeScanner
import SwiftUI
import UserNotifications

struct ProspectsView: View {
    enum FilterType{
        case none,contacted,uncontacted
    }
    let filter: FilterType
    
    @EnvironmentObject var prospects:Prospects
    @State private var isShowingScanner = false
    var body: some View {
        NavigationView{
            List{
                ForEach(filteredProspects){prospect in
                    VStack(alignment: .leading) {
                        Text(prospect.name)
                            .font(.headline)
                        Text(prospect.emailAdress)
                            .foregroundColor(.secondary)
                    }
                    .swipeActions {
                        if prospect.isContacted{
                            Button {
                                prospects.toggle(prospect)
                            } label: {
                                Label("Mark Uncontacted", systemImage: "person.crop.circle.badge.xmark")
                            }
                            .tint(.blue)

                        }else{
                            Button {
                                prospects.toggle(prospect)
                            } label: {
                                Label("Mark Contacted", systemImage: "person.crop.circle.fill.badge.checkmark")
                            }
                            .tint(.green)
                            Button {
                                addNotification(for: prospect)
                            } label: {
                                Label("Remind me", systemImage: "bell")
                            }
                            .tint(.orange)


                        }
                    }
                }
            }
                .navigationTitle(title)
                .toolbar{
                    Button {
                        isShowingScanner = true
                    } label: {
                        Label("Scan", systemImage: "qrcode.viewfinder")
                    }

                }
                .sheet(isPresented: $isShowingScanner) {
                    CodeScannerView(codeTypes: [.qr],simulatedData: "Pelin\npelin@gmail.com" ,completion: handleScan)
                }
        }
    }
    func addNotification(for prospect:Prospect){
        let center = UNUserNotificationCenter.current()
        let addRequest = {
            let content = UNMutableNotificationContent()
            content.title = "Contact \(prospect.name)"
            content.subtitle = "\(prospect.emailAdress)"
            content.sound = UNNotificationSound.default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            center.add(request)
        }
        center.getNotificationSettings { settings in
            if settings.authorizationStatus == .authorized{
                print("\(settings.authorizationStatus)")
                addRequest()
            }else{
                center.requestAuthorization(options:[.alert,.badge,.sound]) { success, error in
                    if success{
                        print("Success")
                        addRequest()
                    }else{
                       print("Denied")
                    }
                }
            }
        }
    }
    var title:String{
        switch filter{
            
        case .none:
            return "Everyone"
        case .contacted:
            return "Contacted People"
        case .uncontacted:
            return "Uncontacted People"
        }
    }
    var filteredProspects: [Prospect]{
        switch filter{
            
        case .none:
            return prospects.people
        case .contacted:
            return prospects.people.filter({$0.isContacted})
        case .uncontacted:
            return prospects.people.filter({!$0.isContacted})
        }
    }
    func handleScan(result:Result<ScanResult,ScanError>){
       isShowingScanner = false
        switch result{
            
        case .success(let result):
            let details = result.string.components(separatedBy: "\n")
            guard details.count == 2 else {return}
            let person = Prospect()
            person.name = details[0]
            person.emailAdress = details[1]
            prospects.add(person)
            
            
        case .failure(let error):
            print("Scanning failed \(error.localizedDescription)")
        }
    }
}

struct ProspectsView_Previews: PreviewProvider {
    static var previews: some View {
        ProspectsView(filter: .none)
    }
}
