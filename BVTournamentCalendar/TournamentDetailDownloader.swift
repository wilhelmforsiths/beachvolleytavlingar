//
//  TournamentDownloader.swift
//  BVTournamentCalendar
//
//  Created by Carl Kenne on 01/06/15.
//  Copyright (c) 2015 Carl Kenne. All rights reserved.
//

import Foundation

class TournamentDetailDownloader {
    var retries = 1
    
    func downloadHTML(tournament:Tournament, callback:(TournamentDetail) -> Void) {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        appDelegate.selectedTournamentDetail = nil
        HttpDownloader().httpGetOld(tournament.link as String){
            (data, error) -> Void in
            if (error != nil) {
                println(error)
                callback(self.createFailedResponse(tournament))
            } else {
                if(self.areWeStillLoggedIn(data!) == true) {
                    var tournamentDetail = self.parseHTML(tournament, HTMLData: data!)
                    callback(tournamentDetail)
                    appDelegate.selectedTournamentDetail = tournamentDetail
                }
                else {
                    self.retries = self.retries - 1
                    if(self.retries < 0){
                        callback(self.createFailedResponse(tournament))
                    }
                    else {
                        //renewing the session by calling the list again
                        TournamentsDownloader().downloadHTML(){ (data) -> Void in
                            sleep(1)
                            self.downloadHTML(tournament, callback: callback)
                        }
                    }
                }
            }
        }
    }
    
    func createFailedResponse(tournament: Tournament) -> TournamentDetail{
        return TournamentDetail(
            link: tournament.link,
            table: "Could not get any information, please try again later.",
            setServerSessionCookieUrl: "",
            fromHour: "",
            toHour: "",
            maxNoOfParticipants: 0
        )
    }
    
    func areWeStillLoggedIn(HTMLData:NSData) -> Bool {
        return TFHpple(HTMLData: HTMLData).searchWithXPathQuery("//h4[contains(.,'Gjestetilgang')]").count == 0
    }
    
    func parseHTML(tournament:Tournament, HTMLData:NSData) -> TournamentDetail {
        var allCells = TFHpple(HTMLData: HTMLData).searchWithXPathQuery("//table")
        var anmalan = TFHpple(HTMLData: HTMLData).searchWithXPathQuery("//input[@value='Anmälan']")
      //  var fromTo = TFHpple(HTMLData: HTMLData).searchWithXPathQuery("//table/tbody/tr[4]//tr[2]")
        var maxNoOfParticipants:String = cleanValue(TFHpple(HTMLData: HTMLData).searchWithXPathQuery("//td[@class='startkont']")[0])
        var maxNo = 100
        if(count(maxNoOfParticipants) > 0){
            maxNo = maxNoOfParticipants.toInt()!
        }
        
        return TournamentDetail(
            link: tournament.link,
            table: (allCells[1] as! TFHppleElement).raw.stringByReplacingOccurrencesOfString("Kontaktinformation", withString: "Kontakt information"),
            setServerSessionCookieUrl: self.extractOnClickLink((anmalan[0] as! TFHppleElement).attributes["onclick"] as! NSString),
            fromHour: "",
            toHour: "",
            maxNoOfParticipants: maxNo
        )
    }
    
    func extractOnClickLink(onclickString: NSString) -> NSString {
        var str = onclickString.stringByReplacingOccurrencesOfString("window.open(\"..", withString: "")
        str = str.stringByReplacingOccurrencesOfString("\", \"_blank\")", withString: "")
        return str
    }
    
    func cleanValue(value:AnyObject) -> String {
        return (value as! TFHppleElement).content.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
    }
}