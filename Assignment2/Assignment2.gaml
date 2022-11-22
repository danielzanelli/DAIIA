/**
* Name: assignment2
* Based on the internal empty template. 
* Author: Mehdi, Daniel
* Tags: 
*/


model assignment2

/* Insert your model definition here */

global {
	
	// PARAMETERS
	int numberOfParticipant <- 30;
	
	float initialPrice <- 1000.0;
	float priceInterval <- 50.0;
	float minPrice <- 500.0;
	
	bool forceNoBid <- false;
	
	bool verbose <- true;
	
	
	init {
		create Participant number:numberOfParticipant;
		create Initiator number:1;
	}
}

species Initiator skills:[fipa]{
	float price <- initialPrice;
	
	list inform1Contents <- ['start of auction'];
	
	list inform2Contents <- ['no bids'];
	bool inform2Time <- false;
	
	bool cfpTime <- false;
	
	list final_bidders <- [];
	Participant final_bidder;
	
	reflex send_inform1 when:(time = 1) {
		write self.name + ': sending inform , start of auction';
		do start_conversation to:Participant.population protocol:'Dutch-inform' performative:'inform' contents:self.inform1Contents;
		self.cfpTime <- true;
	}
	
	reflex send_inform2 when:(self.inform2Time) {
		write self.name + ': sending inform, no bids';
		do start_conversation to:Participant.population protocol:'Dutch-inform' performative:'inform' contents:self.inform2Contents;
	}
	
	reflex send_cfp when:(self.cfpTime) {
		write 'sending call for proposals at price ' + self.price;
		do start_conversation to:Participant.population protocol:'Dutch-cfp' performative:'cfp' contents:['selling my phone', self.price];
		self.cfpTime <- false;
	}
	
	reflex read_cfp when: !empty(cfps) {
		loop p over: cfps {
			if p.contents at 1 {
				self.final_bidders <- self.final_bidders + (p.contents at 0);
			}
		}
		if length(self.final_bidders) >= 1 {
			self.final_bidder <- 1 among self.final_bidders at 0;
			write self.name + ': phone sold to ' + self.final_bidder;
		}
		else {
			self.price <- self.price - priceInterval;
			if self.price > minPrice {
				self.cfpTime <- true;
			}
			else {
				self.inform2Time <- true;
			}
		}
	}
}

species Participant skills:[fipa]{
	float my_bid;
	float auctioner_price;
	
	init{
		if forceNoBid {
			self.my_bid <- minPrice / 2;
		}
		else {
			self.my_bid <- rnd(minPrice, initialPrice);
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
		self.auctioner_price <- cfpFromInitiator.contents at 1;
		if self.auctioner_price > self.my_bid {
			if verbose {
				write self.name + ': price rejected; my bid will be at ' + self.my_bid;
			}
			do cfp message:cfpFromInitiator contents:[self, false];
		}
		else {
			if verbose {
				write self.name + ': price accepted; my bid is at ' + self.my_bid;
			}
			do cfp message:cfpFromInitiator contents:[self, true];
		}
	}
}

