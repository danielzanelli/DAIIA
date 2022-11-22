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
	
	aspect base {
		rgb agentColor <- rgb("blue");
		
		draw square(1) color: agentColor;
	}
	
	reflex send_inform1 when:(time = 1) {
		write self.name + ': sending inform , start of auction';
		do start_conversation to:Participant.population performative:'inform' contents:self.inform1Contents; // protocol:'fipa-inform'
		self.cfpTime <- true;
	}
	
	reflex send_inform2 when:(self.inform2Time) {
		write self.name + ': sending inform, no bids';
		do start_conversation to:Participant.population performative:'inform' contents:self.inform2Contents; // protocol:'fipa-inform'
	}
	
	reflex send_cfp when:(self.cfpTime) {
		write 'sending call for proposals at price ' + self.price;
		do start_conversation to:Participant.population performative:'cfp' contents:['selling my phone', self.price]; // protocol:'fipa-cfp'
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
			write self.name + ': phone sold to ' + self.final_bidder;
		}
		else {
			self.price <- self.price - priceInterval;
			if self.price > minPrice {
				self.cfpTime <- true;
				write self.name + ': no bidder, calling for a lower price';
			}
			else {
				self.inform2Time <- true;
				write self.name + ': no bidder, reached th min price';
			}
		}
	}
}

species Participant skills:[fipa]{
	float my_bid;
	float auctioner_price;
	
	aspect base {
		rgb agentColor <- rgb("green");
		
		draw circle(1) color: agentColor;
	}
	
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
		self.auctioner_price <- cfpFromInitiator.contents[1];
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



experiment gui_experiment type:gui {
	

	parameter "numberOfParticipant" category: "Agents" var:numberOfParticipant;
	
	parameter "initialPrice" var:initialPrice;
	parameter "priceInterval" var:priceInterval;
	parameter "minPrice" var:minPrice;
	
	parameter "forceNoBid" var: forceNoBid;
	parameter "verbose" var: verbose;
	
	output {
		display myDisplay {
			species Initiator aspect:base;
			species Participant aspect:base;
		}
	}
}