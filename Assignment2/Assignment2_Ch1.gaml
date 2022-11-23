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
	int numberOfParticipants <- 10;
	
	map globalAuctionMap <- ['phone':: ['initialPrice'::1000.0 , 'priceInterval'::50.0 , 'minPrice'::500.0 , 'forceNoBid'::false] , 'CD':: ['initialPrice'::10.0 , 'priceInterval'::0.5 , 'minPrice'::5.0 , 'forceNoBid'::false]];
	int numberOfAuctions;
	
	
	bool verbose <- true;
	
	
	init {
		numberOfAuctions <- length(globalAuctionMap);
		create Initiator number:numberOfAuctions;
		create Participant number:numberOfParticipants;
	}
}

species Initiator skills:[fipa]{

	string merch;
	float price;
	float priceInterval;
	float minPrice;
	
	list inform1Contents;
	
	list inform2Contents <- ['no bids'];
	bool inform2Time <- false;
	
	bool cfpTime <- false;
	
	list final_bidders <- [];
	Participant final_bidder;
	
	init {
		int i <- int(regex_matches(self.name, '[0-9]')[0]);
		self.merch <- globalAuctionMap.keys[i];
		self.price <- globalAuctionMap[self.merch]['initialPrice'];
		self.priceInterval <- globalAuctionMap[self.merch]['priceInterval'];
		self.minPrice <- globalAuctionMap[self.merch]['minPrice'];
		self.inform1Contents <- ['start of the auction of : ', self.merch];
		
		write  self.name + ' - ' + self.merch + ' - ' + self.price  + ' - ' + self.priceInterval  + ' - ' + self.minPrice  + ' - ' + self.inform1Contents;
	}
	

	aspect base {
		rgb agentColor <- rgb("blue");
		
		draw square(2) color: agentColor;
	}
	
	reflex send_inform1 when:(time = 1) {
		write self.name + ': sending inform , start of auction ' + self.merch;
		do start_conversation to:Participant.population performative:'inform' contents:self.inform1Contents; // protocol:'fipa-inform'
		self.cfpTime <- true;
	}
	
	reflex send_inform2 when:(self.inform2Time) {
		write self.name + ': sending inform, no bids';
		do start_conversation to:Participant.population performative:'inform' contents:self.inform2Contents; // protocol:'fipa-inform'
		inform2Time <- false;
	}
	
	reflex send_cfp when:(self.cfpTime) {
		write 'sending call for proposals at price ' + self.price;
		do start_conversation to:Participant.population performative:'cfp' contents:[self.merch, self.price]; // protocol:'fipa-cfp'
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
			write self.name + ': '+ self.merch + ' sold to ' + self.final_bidder;
		}
		else {
			self.price <- self.price - self.priceInterval;
			if self.price > self.minPrice {
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
	
	map participantAuctionMap <- ['phone':: ['my_bid'::0.0 , 'auctioner_price'::0.0] , 'CD':: ['my_bid'::0.0 , 'auctioner_price'::0.0]];
	
	
	aspect base {
		rgb agentColor <- rgb("green");
		
		draw circle(1) color: agentColor;
	}
	
	init{
		loop merch over: globalAuctionMap.keys {
			if globalAuctionMap[merch]['forceNoBid'] {
				participantAuctionMap[merch]['my_bid'] <- 0.0;
			}
			else {
				participantAuctionMap[merch]['my_bid'] <- rnd(float(globalAuctionMap[merch]['minPrice']), float(globalAuctionMap[merch]['initialPrice']));
			}
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
		string merch <- cfpFromInitiator.contents[0];
		participantAuctionMap[merch]['auctioner_price'] <- cfpFromInitiator.contents[1];
		if participantAuctionMap[merch]['auctioner_price'] > participantAuctionMap[merch]['my_bid'] {
			if verbose {
				write self.name + ': price rejected; my bid will be at ' + participantAuctionMap[merch]['my_bid'];
			}
			do cfp message:cfpFromInitiator contents:[self, false];
		}
		else {
			if verbose {
				write self.name + ': price accepted; my bid is at ' + participantAuctionMap[merch]['my_bid'];
			}
			do cfp message:cfpFromInitiator contents:[self, true];
		}
	}
}



experiment gui_experiment type:gui {
	

	parameter "numberOfParticipants" category: "Agents" var:numberOfParticipants;
	
	parameter "globalAuctionMap" var:globalAuctionMap;
	
	parameter "verbose" var: verbose;
	
	output {
		display myDisplay {
			species Initiator aspect:base;
			species Participant aspect:base;
		}
	}
}