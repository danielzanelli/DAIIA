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
	
	int newActEvery <- 100;
	
	ChessBoard myCell; 
	int id; 
	int index <- 0;
	bool informNewAct;
	float size <- 20/numberOfStages;
	
	init{
		lightshow_quality <- rnd( 0.0, 100.0 );
		speaker_quality <- rnd( 0.0, 100.0 );
		band_quality <- rnd( 0.0, 100.0 );
		act <- [lightshow_quality, speaker_quality, band_quality];
		informNewAct <- true;
	}
       
    //reflex updateCell {
    //	write('id' + id);
    //	write('X: ' + myCell.grid_x + ' - Y: ' + myCell.grid_y);
    //	myCell <- ChessBoard[myCell.grid_x,  mod(index, numberOfQueens)];
    //	location <- myCell.location;
    //	index <- index + 1;
    //}
    
    reflex newAct when: (int(time) mod newActEvery = 0) {
    	write string(time) + "\tNew act on \t" + self;
		lightshow_quality <- rnd( 0.0, 100.0 );
		speaker_quality <- rnd( 0.0, 100.0 );
		band_quality <- rnd( 0.0, 100.0 );
		act <- [lightshow_quality, speaker_quality, band_quality];

		write self.name + ': sending inform, start of act';
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
	
	float distanceThreshold <- 10.0;
	
	list utility <-[];
	list stages <- [];
	
	Stage target <- nil;
	Stage watchingAct <- nil;
	
	init{
		preference_lightshow <- rnd( 0.0, 100.0 );
		preference_speakers <- rnd( 0.0, 100.0 );
		preference_band <- rnd( 0.0, 100.0 );
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
			if(s = informFromInitiator.contents[0]){
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
		watchingAct <- nil;
		write self.name + ':\t going to stage:\t' + target;
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
	output{
		display ChessBoard{
			grid ChessBoard border: #black ;
			species Stage aspect: base;
			species Person aspect: base;
		}
	}
}