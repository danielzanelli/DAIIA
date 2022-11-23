/**
* Name: Assignment2Ch1
* Based on the internal empty template. 
* Author: Mehdi, Daniel
* Tags: 
*/


model Assignment2Ch1

/* Insert your model definition here */

global {
	
	// PARAMETERS
	int numberOfParticipant <- 1;
	int numberOfInitiators <- 100;
	

	float priceInterval <- 50.0;
	
	float minPrice <- 500.0;	
	float maxPrice <- 1000.0;
	
	bool forceNoBid <- false;
	
	bool verbose <- false;
	
	
	init {
		create Participant number:numberOfParticipant;
		
		loop counter from: 1 to: numberOfInitiators {			
        	
			if (counter mod 3 = 0){
				create DutchInitiator;
			}
			if (counter mod 3 = 1){
				create EnglishInitiator;
			}
			if (counter mod 3 = 2){
				create SealedInitiator;
			}

        }
        
	}
}


species DutchInitiator skills:[fipa]{
	
	float price <- maxPrice;
	float pevious_budget;
	
	list inform1Contents <- ['start of auction'];
	
	list inform2Contents <- ['no bids'];
	bool inform2Time <- false;
	
	bool cfpTime <- false;
	
	list final_bidders <- [];
	Participant final_bidder;

	
	reflex send_inform1 when:(time = 1) {
		write self.name + ': sending inform, start of auction';
		do start_conversation to:Participant.population performative:'inform' contents:self.inform1Contents; // protocol:'fipa-inform'
		self.cfpTime <- true;
	}
	
	reflex send_inform2 when:(self.inform2Time) {
		write self.name + ': sending inform, no bids';
		do start_conversation to:Participant.population performative:'inform' contents:self.inform2Contents; // protocol:'fipa-inform'
		self.inform2Time <- false;
	}
	
	reflex send_cfp when:(self.cfpTime) {
		if(verbose){
			write 'sending call for proposals at price ' + self.price;
		}
		do start_conversation to:Participant.population performative:'cfp' contents:['dutch', self.price]; // protocol:'fipa-cfp'
		self.cfpTime <- false;
	}
	
	reflex read_cfp when: !empty(cfps) {
		loop p over: cfps {
			if p.contents[1] {
				self.final_bidders <- self.final_bidders + (p.contents[0]);
			}
		}
		if length(self.final_bidders) >= 1 {
			self.final_bidder <- 1 among self.final_bidders at 0;
			write self.name + ": auction done, sold to: " + self.final_bidder + " for: " + self.price;
			if forceNoBid {
				self.final_bidder.budget <- 0.0;
				write "Participant Re-Initiated with budget:\t" + self.final_bidder.budget;
			}
			else {
				self.final_bidder.dutch_utility <- self.final_bidder.dutch_utility + (self.final_bidder.budget - self.price);
				write "\nParticipant Utilities:\t Dutch: " + self.final_bidder.dutch_utility + "\tEnglish: "+ self.final_bidder.english_utility +  "\tSealed: "+ self.final_bidder.sealed_utility + '\n';
				self.final_bidder.budget <- rnd(minPrice, maxPrice);
				write "Participant Re-Initiated with budget:\t" + self.final_bidder.budget + '\n';
			}
			self.inform2Time <- true;
			self.cfpTime <- false;
		}
		else {
			self.price <- self.price - priceInterval;
			if self.price > minPrice {
				self.cfpTime <- true;
				if(verbose){
					write self.name + ': no bidder, calling for a lower price';
				}
			}
			else {
				self.inform2Time <- true;
				write self.name + ': auction done without sale, reached min price';
			}
		}
	}
	
}


species EnglishInitiator skills:[fipa]{
	
	
	list inform1Contents <- ['start of auction'];
	
	list inform2Contents <- ['no bids'];
	bool inform2Time <- false;
	
	bool cfpTime <- false;
	
	Participant max_bidder;
	Participant previous_bidder;
	float price <- minPrice;
	float previous_budget;

	
	reflex send_inform1 when:(time = 1) {
		write self.name + ': sending inform, start of auction';
		do start_conversation to:Participant.population performative:'inform' contents:self.inform1Contents; // protocol:'fipa-inform'
		self.cfpTime <- true;
	}
	
	reflex send_inform2 when:(self.inform2Time) {
		write self.name + ': sending inform, no bids';
		do start_conversation to:Participant.population performative:'inform' contents:self.inform2Contents; // protocol:'fipa-inform'
		self.inform2Time <- false;
	}
	
	reflex send_cfp when:(self.cfpTime) {
		if(verbose){
			write 'sending call for proposals at price ' + self.price;
		}
		do start_conversation to:Participant.population performative:'cfp' contents:['english', self.price]; // protocol:'fipa-cfp'
		self.cfpTime <- false;
	}
	
	reflex read_cfp when: !empty(cfps) {
		float maxOffer <- 0.0;
		loop p over: cfps {
			if bool(p.contents[1]) {
				if(float(p.contents[2]) > maxOffer){
					maxOffer <- float(p.contents[2]);
					self.max_bidder <- p.contents[0];
				}
			}
		}
		if self.price > maxOffer {
			self.inform2Time <- true;
			self.cfpTime <- false;
			if(self.previous_bidder = nil){
				write self.name + ": no bids were made, bid over without sale";
			}
			else{
				write self.name + ": no bids this round, winner is previous highest bidder";
				write self.name + ": auction done, sold to: " + self.previous_bidder + " for: " + self.price;
				if forceNoBid {
					self.previous_bidder.budget <- 0.0;
					write "Participant Re-Initiated with budget:\t" + self.previous_bidder.budget;
				}
				else {
					self.previous_bidder.english_utility <- self.previous_bidder.english_utility + (self.previous_budget - self.price);
				write "\nParticipant Utilities:\t Dutch: " + self.previous_bidder.dutch_utility + "\tEnglish: "+ self.previous_bidder.english_utility +  "\tSealed: "+ self.previous_bidder.sealed_utility + '\n';
					self.previous_bidder.budget <- rnd(minPrice, maxPrice);
					write "Participant Re-Initiated with budget:\t" + self.previous_bidder.budget + '\n';
				}
				self.inform2Time <- true;
				self.cfpTime <- false;
			}
		}
		else {
			self.price <- maxOffer;
			self.previous_bidder <- self.max_bidder;
			self.previous_budget <- self.max_bidder.budget;
			if(verbose){
				write self.name + ": bid received, current bid price: " + self.price;
			}
			self.cfpTime <- true;
		}
		
	}
	
}


species SealedInitiator skills:[fipa]{
	
	list inform1Contents <- ['start of auction'];
	
	list inform2Contents <- ['no bids'];
	bool inform2Time <- false;
	
	bool cfpTime <- false;
	
	bool done <- false;
	Participant final_bidder;

	
	reflex send_inform1 when:(time = 1) {
		write self.name + ': sending inform, start of auction';
		do start_conversation to:Participant.population performative:'inform' contents:self.inform1Contents; // protocol:'fipa-inform'
		self.cfpTime <- true;
	}
	
	reflex send_inform2 when:(self.inform2Time) {
		write self.name + ': sending inform, no bids';
		do start_conversation to:Participant.population performative:'inform' contents:self.inform2Contents; // protocol:'fipa-inform'
		self.inform2Time <- false;
	}
	
	reflex send_cfp when:(self.cfpTime) {
		write 'Sending call for sealed proposals';
		do start_conversation to:Participant.population performative:'cfp' contents:['sealed']; // protocol:'fipa-cfp'
		self.cfpTime <- false;
	}
	
	reflex read_cfp when: !empty(cfps) {
		float maxOffer <- 0.0;
		loop p over: cfps {
			if bool(p.contents[1]) {
				if(float(p.contents[2]) > maxOffer){
					maxOffer <- float(p.contents[2]);
					self.final_bidder <- p.contents[0];
				}
			}
		}
		if  maxOffer < minPrice {
			self.inform2Time <- true;
			self.cfpTime <- false;			
			write self.name + ': auction done without selling';
		}			
		
		else {
			write self.name + ": auction done, sold to: " + self.final_bidder + " for: " + maxOffer;
			if forceNoBid {
				self.final_bidder.budget <- 0.0;
				write "Participant Re-Initiated with budget:\t" + self.final_bidder.budget;
			}
			else {
				write "\nParticipant Utilities:\t Dutch: " + self.final_bidder.dutch_utility + "\tEnglish: "+ self.final_bidder.english_utility +  "\tSealed: "+ self.final_bidder.sealed_utility + '\n';
				self.final_bidder.budget <- rnd(minPrice, maxPrice);
				write "Participant Re-Initiated with budget:\t" + self.final_bidder.budget + '\n';
			}
			self.inform2Time <- true;
			self.cfpTime <- false;
		}
			
	}
}
	





species Participant skills:[fipa]{
	float budget;
	float dutch_utility <-0.0;
	float english_utility <-0.0;
	float sealed_utility <-0.0;
	//float auctioner_price;
	
	init{
		if forceNoBid {
			self.budget <- 0.0;
			write "Participant Initiated with budget:\t" + self.budget;
		}
		else {
			self.budget <- rnd(minPrice, maxPrice);
			write self.name  +" Initiated with budget:\t" + self.budget;
		}
	}
	
	reflex write_inform_msg when: !empty(informs) {
		message informFromInitiator <- (informs at 0);
		if verbose {
			write self.name + ':\treceived inform msg:\t' + informFromInitiator.contents;
		}
	}
	
	reflex reply_cfp_msg when: !empty(cfps) {
		message cfpFromInitiator <- (cfps at 0);
		if verbose {
			write self.name + ':\treceived cfp msg:\t' + cfpFromInitiator.contents;
		}
		if (cfpFromInitiator.contents[0] = 'dutch'){
			
			if float(cfpFromInitiator.contents[1]) > self.budget {
				if verbose {
					write "(dutch)\t" +self.name + ':\tprice rejected; willing to pay ' + self.budget;
				}
				do cfp message:cfpFromInitiator contents:[self, false];
			}
			else {
				if verbose {
					write "(dutch)\t" +self.name + ':\tprice accepted; willing to pay ' + self.budget;
				}
				do cfp message:cfpFromInitiator contents:[self, true];
			}			
		}
		else if(cfpFromInitiator.contents[0] = 'english'){
			
			if float(cfpFromInitiator.contents[1]) + priceInterval > self.budget {
				if verbose {
					write  "(english)\t" + self.name + ':\tprice rejected; willing to pay ' + self.budget;
				}
				do cfp message:cfpFromInitiator contents:[self, false, self.budget];
			}
			else {
				if verbose {
					write "(english)\t" +self.name + ':\tparticipating in english auction, bidding price: ' + (float(cfpFromInitiator.contents[1]) + priceInterval);
				}
				do cfp message:cfpFromInitiator contents:[self, true, (float(cfpFromInitiator.contents[1]) + priceInterval)];
			}			
		}
		else if(cfpFromInitiator.contents[0] = 'sealed'){		
			if verbose {
				write "(sealed)\t" +self.name + ':\tparticipating in sealed auction, bidding price: ' + self.budget;
			}	
			do cfp message:cfpFromInitiator contents:[self, true, self.budget];
		}
		
	}
}



experiment gui_experiment {
	

	parameter "Participants" category: "Agents" var:numberOfParticipant;
	parameter "Auctioners" category: "Agents" var:numberOfInitiators;
	parameter "Auction Price Interval" category: "Agents"  var:priceInterval;
	parameter "Min Auction Price" category: "Agents"  var:minPrice;
	parameter "Max Auction Price" category: "Agents"  var:maxPrice;
	parameter "Force no-bid" category: "Agents"  var: forceNoBid;	
	parameter "verbose" category: "Agents" var: verbose;
	

}