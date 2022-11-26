/**
* Name: Assignment3
* Based on the internal empty template. 
* Author: Daniel, Medhi 
* Tags: 
*/


model Assignment3


global {
	
	int numberOfStages <- 5;
	int numberOfPeople <- 100;
	
	float distanceThreshold <- 10.0;	
	int newActEvery <- 100;
	
	bool verbose <- true;

	init {
		create Person number: numberOfPeople;
		create Stage number: numberOfStages;
		int index <- 0;		
		loop counter from: 1 to: numberOfStages {
        	Stage stage <- Stage[counter - 1];
        	stage <- stage.setId(index);
        	stage <- stage.initializeCell();
        	index <- index + 1;
        }
	}
}


species Stage skills: [fipa]{
    
	float lightshow_quality;
	float speaker_quality;
	float band_quality;
	
	list act;
	int people_coming;
	int people_here;
	
	
	ChessBoard myCell; 
	int id; 
	int index <- 0;
	bool informNewAct;
	float size <- 20/numberOfStages;
	
	init{
		lightshow_quality <- rnd( 0.0, 1.0 );
		speaker_quality <- rnd( 0.0, 1.0 );
		band_quality <- rnd( 0.0, 1.0 );
		act <- [lightshow_quality, speaker_quality, band_quality];
		informNewAct <- true;
	}
    
    reflex newAct when: (int(time) mod newActEvery = 0) {
    	if(verbose){
    		write string(time) + "\tNew act on \t" + self;
    	}
		lightshow_quality <- rnd( 0.0, 1.0 );
		speaker_quality <- rnd( 0.0, 1.0 );
		band_quality <- rnd( 0.0, 1.0 );
		act <- [lightshow_quality, speaker_quality, band_quality];
		if(verbose){
			write self.name + ': sending inform, start of act';
		}
		do start_conversation to:Person.population performative:'inform' contents:[act, self]; // protocol:'fipa-inform'
	}
	
    
	action setId(int input) {
		id <- input;
	}
	
	action initializeCell {
		myCell <- ChessBoard[id, id];
	}
	
	
	aspect base {
        draw circle(size) color: #blue ;
       	location <- myCell.location ;
    }

}

species Person skills: [moving,  fipa]{
	
	float preference_lightshow;
	float preference_speakers;
	float preference_band;
	
	
	list utility <-[];
	list stages <- [];
	
	Stage target <- nil;
	Stage watchingAct <- nil;
	
	init{
		preference_lightshow <- rnd( 0.0, 1.0 );
		preference_speakers <- rnd( 0.0, 1.0 );
		preference_band <- rnd( 0.0, 1.0 );
	}
	
	reflex arrivedToStage when:!empty(Stage at_distance distanceThreshold){
		ask Stage at_distance distanceThreshold {
			if(myself.target = self){
				myself.target <- nil;
				myself.watchingAct <- self;
			}
		}
	}
	reflex watchAct{
		if(watchingAct != nil){
			bool nearby <- false;
			loop ag over: agents_at_distance(distanceThreshold){
				if(ag = watchingAct){
					nearby <- true;
					break;
				}
			}
			if(!nearby){
				target <- watchingAct;
			}
		}
	}
	
	reflex receiveNewAct when: !empty(informs) {
		message informFromInitiator <- (informs at 0);
		if verbose {
			write self.name + ':\treceived inform msg:\t' + informFromInitiator.contents;
		}
		int i <- 0;
		loop s over: stages{
			if(s = informFromInitiator.contents[1]){
				stages <- stages - s;
				utility <- utility - utility[i];
			} 
			i <- i+1;
		}
		utility <- utility + [float(informFromInitiator.contents[0][0]) * float(preference_lightshow) + 
			float(informFromInitiator.contents[0][1]) * float(preference_speakers) +
			float(informFromInitiator.contents[0][2]) * float(preference_band)
		];
		stages <- stages + [informFromInitiator.contents[1]];
		target <- stages[index_of(utility, max(utility))];
		
		if(verbose){
			write self.name + ':\t utility:\t' + utility;
			write self.name + ':\t stages:\t' + stages;			
		}
		
		if (target = watchingAct){
			target <- nil;
			if(verbose){
				write self.name + ':\t staying at stage:\t' + watchingAct;
			}
		}
		else{
			watchingAct <- nil;			
			if(verbose){
				write self.name + ':\t going to stage:\t' + target;
			}
		}
	}
	
	aspect base {
		rgb agentColor <- rgb("purple");		
		draw circle(1) color: agentColor;
	}
	
	reflex move {
		speed <- 0.5;
		if(target != nil){
			do goto target: target;
		} else{
			do wander;
		}
	}
}
    
    
grid ChessBoard width: numberOfStages height: numberOfStages { 
	init{
		if(even(grid_x) and even(grid_y)){
			color <- #black;
		}
		else if (!even(grid_x) and !even(grid_y)){
			color <- #black;
		}
		else {
			color <- #white;
		}
	}		

}

experiment Assignment3 type: gui{	

	parameter "People" category: "Agents" var:numberOfPeople;
	parameter "Stages" category: "Agents" var:numberOfStages;
	parameter "Distance Threshold" category: "Agents"  var:distanceThreshold;
	parameter "New Act Every" category: "Agents"  var:newActEvery;
	parameter "Verbose" category: "Agents" var: verbose;
	
	output{
		display ChessBoard{
			grid ChessBoard border: #black ;
			species Stage aspect: base;
			species Person aspect: base;
		}
	}
}