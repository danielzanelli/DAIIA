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
	int numberOfParticipant <- 30;
	int numberOfInitiators <- 3;
	

	float priceInterval <- 50.0;
	
	float minPrice <- 500.0;	
	float maxPrice <- 1000.0;
	
	bool forceNoBid <- false;
	
	bool verbose <- true;
	
	
	init {
		create Participant number:numberOfParticipant;
		
		loop counter from: 1 to: numberOfInitiators {			
        	
			if (counter mod 3 = 0){
				create DutchInitiator;
			}
			if (counter mod 3 = 1){
				create BritishInitiator;
			}
			if (counter mod 3 = 2){
				create SealedInitiator;
			}

        }
        
	}
}


species DutchInitiator skills:[fipa]{
	
	float price <- maxPrice;
	
	list inform1Contents <- ['start of auction'];
	
	list inform2Contents <- ['no bids'];
	bool inform2Time <- false;
	
	bool cfpTime <- false;
	
	list final_bidders <- [];
	Participant final_bidder;

	
	reflex send_inform1 when:(time = 1) {
		write self.name + ': sending inform , start of auction';
		do start_conversation to:Participant.population performative:'inform' contents:self.inform1Contents; // protocol:'fipa-inform'
		self.cfpTime <- true;
	}
	
	reflex send_inform2 when:(self.inform2Time) {
		write self.name + ': sending inform, no bids';
		do start_conversation to:Participant.population performative:'inform' contents:self.inform2Contents; // protocol:'fipa-inform'
		self.inform2Time <- false;
	}
	
	reflex send_cfp when:(self.cfpTime) {
		write 'sending call for proposals at price ' + self.price;
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
			write self.name + ': stuff sold to ' + self.final_bidder;
		}
		else {
			self.price <- self.price - priceInterval;
			if self.price > minPrice {
				self.cfpTime <- true;
				write self.name + ': no bidder, calling for a lower price';
			}
			else {
				self.inform2Time <- true;
				write self.name + ': auction done without sale, reached min price';
			}
		}
	}
	
}


species BritishInitiator skills:[fipa]{
	
	float price <- minPrice;
	
	list inform1Contents <- ['start of auction'];
	
	list inform2Contents <- ['no bids'];
	bool inform2Time <- false;
	
	bool cfpTime <- false;
	
	bool done <- false;
	Participant final_bidder;

	
	reflex send_inform1 when:(time = 1) {
		write self.name + ': sending inform , start of auction';
		do start_conversation to:Participant.population performative:'inform' contents:self.inform1Contents; // protocol:'fipa-inform'
		self.cfpTime <- true;
	}
	
	reflex send_inform2 when:(self.inform2Time) {
		write self.name + ': sending inform, no bids';
		do start_conversation to:Participant.population performative:'inform' contents:self.inform2Contents; // protocol:'fipa-inform'
		self.inform2Time <- false;
	}
	
	reflex send_cfp when:(self.cfpTime) {
		write 'sending call for proposals at price ' + self.price;
		do start_conversation to:Participant.population performative:'cfp' contents:['british', self.price]; // protocol:'fipa-cfp'
		self.cfpTime <- false;
	}
	
	reflex read_cfp when: !empty(cfps) {
		if(not done){
			float maxOffer <- 0.0;
			loop p over: cfps {
				if bool(p.contents[1]) {
					if(float(p.contents[2]) > maxOffer){
						maxOffer <- float(p.contents[2]);
						self.final_bidder <- p.contents[0];
					}
				}
			}
			if self.price > maxOffer {
				self.inform2Time <- true;
				self.cfpTime <- false;
				if(self.final_bidder = nil){
					write self.name + ": auction done without sale, max bid too low: " + maxOffer;
				}
				else{
					write self.name + ': auction done, stuff sold to: ' + self.final_bidder;
				}
			}
			else {
				self.price <- maxOffer;
				write self.name + ": bid received, current bid price: " + self.price;
				self.cfpTime <- true;
			}
			
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
		write self.name + ': sending inform , start of auction';
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
		if(not done){
			float maxOffer <- 0.0;
			loop p over: cfps {
				if bool(p.contents[1]) {
					if(float(p.contents[2]) > maxOffer){
						maxOffer <- float(p.contents[2]);
						self.final_bidder <- p.contents[0];
					}
				}
			}
			if minPrice > maxOffer {
				self.inform2Time <- true;
				self.cfpTime <- false;
				if(self.final_bidder = nil){
					write self.name + ": auction done without sale, max bid too low: " + maxOffer;
				}
				else{
					write self.name + ': auction done, stuff sold to: ' + self.final_bidder;
				}
			}
			else {
				write self.name + ": auction done, sold to: " + self.final_bidder + " for: " + maxOffer;
				self.inform2Time <- true;
				self.cfpTime <- false;
			}
			
		}
	}
	
}





species Participant skills:[fipa]{
	float budget;
	//float auctioner_price;
	
	init{
		if forceNoBid {
			self.budget <- minPrice / 2;
		}
		else {			
			self.budget <- rnd(minPrice, maxPrice);
		}
	}
	
	reflex write_inform_msg when: !empty(informs) {
		message informFromInitiator <- (informs at 0);
		if verbose {
			write self.name + ': received inform msg, ' + informFromInitiator.contents;
		}
	}
	
	reflex reply_cfp_msg when: !empty(cfps) {
		message cfpFromInitiator <- (cfps at 0);
		if verbose {
			write self.name + ': received cfp msg, ' + cfpFromInitiator.contents;
		}
		if (cfpFromInitiator.contents[0] = 'dutch'){
			
			if float(cfpFromInitiator.contents[1]) > self.budget {
				if verbose {
					write self.name + ': price rejected; willing to pay ' + self.budget;
				}
				do cfp message:cfpFromInitiator contents:[self, false];
			}
			else {
				if verbose {
					write self.name + ': price accepted; willing to pay ' + self.budget;
				}
				do cfp message:cfpFromInitiator contents:[self, true];
			}			
		}
		else if(cfpFromInitiator.contents[0] = 'british'){
			
			if float(cfpFromInitiator.contents[1]) + priceInterval > self.budget {
				if verbose {
					write self.name + ': price rejected; willing to pay ' + self.budget;
				}
				do cfp message:cfpFromInitiator contents:[self, false, self.budget];
			}
			else {
				if verbose {
					write self.name + ': participating in british auction, bidding price: ' + (float(cfpFromInitiator.contents[1]) + priceInterval);
				}
				do cfp message:cfpFromInitiator contents:[self, true, (float(cfpFromInitiator.contents[1]) + priceInterval)];
			}			
		}
		else if(cfpFromInitiator.contents[0] = 'sealed'){		
			if verbose {
				write self.name + ': participating in sealed auction, bidding price: ' + self.budget;
			}	
			do cfp message:cfpFromInitiator contents:[self, true, self.budget];
		}
		
	}
}



experiment gui_experiment type:gui {
	

	parameter "numberOfParticipant" category: "Agents" var:numberOfParticipant;
	
	//parameter "initialPrice" var:initialPrice;
	parameter "priceInterval" var:priceInterval;
	parameter "minPrice" var:minPrice;
	
	parameter "forceNoBid" var: forceNoBid;
	parameter "verbose" var: verbose;
	

}