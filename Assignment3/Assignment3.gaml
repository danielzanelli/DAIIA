/**
* Name: Assignment3
* Based on the internal empty template. 
* Author: Daniel, Medhi 
* Tags: 
*/


model Assignment3


global {
	
	int numberOfStages <- 12;
	int numberOfPeople <- 50;
	
	float distanceThreshold <- 1.0;
	int newActEvery <- 500;
	
	bool verbose <- true;
	
	bool queens_ok <- false;

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
	
	float props_quality;
	float instrument_quality;
	float vocals_quality;
	
	list act;
	list people_coming;
	
	bool respond_cfp <- false;	
	
	ChessBoard myCell; 
	int id; 
	int index <- 0;
	float size <- 20/numberOfStages;
	
	Stage predecessor;
	Stage successor;
	
	list reposRequestContents <- ['repostion'];
	bool sendPredReposReqTime <- false;
	
	bool successorInformTime <- false;
	list informSuccessorContents <- ['reposition done'];
	
	list<ChessBoard> predsCell  <- [];
	list previous_poses <- [];
	int num_back_traces <- 0;
	
	
	init{
		lightshow_quality <- rnd( 0.0, 1.0 );
		speaker_quality <- rnd( 0.0, 1.0 );
		band_quality <- rnd( 0.0, 1.0 );
		props_quality <- rnd( 0.0, 1.0 );
		instrument_quality <- rnd( 0.0, 1.0 );
		vocals_quality <- rnd( 0.0, 1.0 );
		act <- [lightshow_quality, speaker_quality, band_quality, props_quality, instrument_quality, vocals_quality];
		
		self.id <- int(regex_matches(self.name, '[0-9]+$')[0]);
		do initializeCell;

		if self.id >= 1 {
			self.predecessor <- Stage[self.id - 1];
		}
		if self.id <= numberOfStages - 2 {
			self.successor <- Stage[self.id + 1];
		}
		if self.id = 0 {
			self.successorInformTime <- true;
		}
	}
	
	action initializeCell {
		myCell <- ChessBoard[id, id];
	}
    
    reflex newAct when: (int(time) mod newActEvery = 0 and queens_ok) {
    	if(verbose){
    		write string(time) + "\tNew act on \t" + self;
    	}
		lightshow_quality <- rnd( 0.0, 1.0 );
		speaker_quality <- rnd( 0.0, 1.0 );
		band_quality <- rnd( 0.0, 1.0 );
		props_quality <- rnd( 0.0, 1.0 );
		instrument_quality <- rnd( 0.0, 1.0 );
		vocals_quality <- rnd( 0.0, 1.0 );
		act <- [lightshow_quality, speaker_quality, band_quality, props_quality, instrument_quality, vocals_quality];
		if(verbose){
			write self.name + ': sending inform, start of act';
		}
		do start_conversation to:Person.population performative:'inform' contents:[act, self]; // protocol:'fipa-inform'
		people_coming <- [];
	}
	
	
	reflex read_cfp when: !empty(cfps) {
		loop p over: cfps {
			if p.contents[0] = 'going to stage' {
				if !(p.contents[1] in people_coming){
					people_coming <- people_coming + p.contents[1];
				}
			}
			else if p.contents[0] = 'leaving stage'{
				people_coming <- people_coming - p.contents[1];
			}
		}
		if length(people_coming)>0{
			respond_cfp <- true;
		}
	}
	
	reflex send_cfp when:respond_cfp {
		do start_conversation to:Person.population performative:'cfp' contents:[length(people_coming)/numberOfPeople, self, act]; // protocol:'fipa-cfp'
		respond_cfp <- false;
	}
	
    
	action setId(int input) {
		id <- input;
	}
	
	
	aspect base {
        draw circle(size) color: #orange ;
       	location <- myCell.location ;
    }
    
    
    reflex send_predecessor_request when:(self.id >= 1 and self.sendPredReposReqTime) {
		if verbose {
			write self.name + ': sending request to predecessor, repostion';
		}
		
		do start_conversation to:[self.predecessor] performative:'request' contents:self.reposRequestContents; // protocol:'fipa-inform'
		self.sendPredReposReqTime <- false;
	}
    
    reflex read_successor_request when: !empty(requests) {
		message requestFromSuccessor <- (requests at 0);
		if verbose {
			write self.name + ': received request msg, ' + requestFromSuccessor.contents;
		}
		if requestFromSuccessor.contents[0] = self.reposRequestContents[0] {
			self.num_back_traces <- self.num_back_traces + 1;
			bool repose_bool <- self.repose();
			if repose_bool {
				if verbose {
					write self.name + ': reposed to another available cell -> (' + myCell.grid_x + ', ' + myCell.grid_y + ')';
				}
				self.successorInformTime <- true;
			}
			else {
				self.sendPredReposReqTime <- true;
				if verbose {
					write self.name + ': reposition is not possible';
				}
			}
		}
	}
	
	action updateCell (int col) {
    	myCell <- ChessBoard[col, myCell.grid_y];
    	self.previous_poses <- self.previous_poses + myCell;
    	write self.name + ': my new cell is ' + myCell + ': (' + myCell.grid_x + ', ' + myCell.grid_y + ')';
    	self.location <- myCell.location;
    }
	
	bool isSafe (int col) {
		point target_p <- {col, self.myCell.grid_y};
		loop predCell over: self.predsCell {
			point predCellPoint <- {predCell.grid_x, predCell.grid_y};
			if predCellPoint.x = target_p.x {
				if verbose {
					write self.name + ': can be attacked from same column at ' + target_p;
				}
				return false;
			}
			// Let's see if we hit this target point by other preds in upper left part
			loop while: (predCellPoint.x <= numberOfStages) and (predCellPoint.y <= numberOfStages) {
				if predCellPoint = target_p {
					if verbose {
						write (self.name + ': can be attacked from upper left dir at ' + predCellPoint);
					}
					return false;
				}
				predCellPoint <- predCellPoint + {1 , 1};
			}
			// Let's see if we hit this target point by other preds in upper right part
			predCellPoint <- {predCell.grid_x, predCell.grid_y};
			loop while: (predCellPoint.x >= 0) and (predCellPoint.y <= numberOfStages) {
				if predCellPoint = target_p {
					if verbose {
						write self.name + ': can be attacked from upper right dir at ' + predCellPoint;
					}
					return false;
				}
				predCellPoint <- predCellPoint + {-1 , 1};
//				write self.name + ': predCellPoint now is ' + predCellPoint + ' - target_p now is ' + target_p;
			}
		}
		return true;
	}
	
	bool repose {
		self.predsCell <- [];
		loop q over: Stage.population {
			if q.id < self.id {
				self.predsCell <- self.predsCell + q.myCell;
			}
		}
		int temp <- self.num_back_traces;
		loop col from:0 to:(numberOfStages-1) {
			if verbose {
					write self.name + ': checking column ' + col;
				}
			if self.isSafe(col:col) {
				if temp = 0 {
					do updateCell(col:col);
					return true;
				}
				temp <- temp - 1;
				if verbose {
					write self.name + ': jump over my previous column ' + col;
				}
			}
		}
		return false;
	}
	
	reflex send_successor_inform when:(self.id <= (numberOfStages - 2) and self.successorInformTime and !queens_ok) {
		if verbose {
			write self.name + ': sending inform to successor , reposition done';
		}
		do start_conversation to:[self.successor] performative:'inform' contents:self.informSuccessorContents; // protocol:'fipa-inform'
		self.successorInformTime <- false;
	}
    
    reflex read_predecessor_inform when: !empty(informs) {
		message informFromPredecessor <- (informs at 0);
		if verbose {
			write self.name + ': received inform msg, ' + informFromPredecessor.contents;
		}
		if informFromPredecessor.contents[0] = self.informSuccessorContents[0] {
			self.num_back_traces <- 0;
			bool repose_bool <- self.repose();
			if repose_bool {
				if verbose {
					write self.name + ': reposed to another available cell -> (' + myCell.grid_x + ', ' + myCell.grid_y + ')';
				}
				self.successorInformTime <- true;
				if self.id > (numberOfStages - 2) {
					queens_ok <- true;
				}
			}
			else {
				self.sendPredReposReqTime <- true;
				if verbose {
					write self.name + ': reposition is not possible';
				}
			}
		}
	}

}

species Person skills: [moving,  fipa]{
	
	float preference_lightshow;
	float preference_speakers;
	float preference_band;
	
	float preference_props;
	float preference_instruments;
	float preference_vocals;
	
	
	float crowd_affinity;
	
	list utility <-[];
	list stages <- [];
	
	Stage target <- nil;
	Stage previousTarget <- nil;
	Stage watchingAct <- nil;
	
	init{
		preference_lightshow <- rnd( 0.0, 1.0 );
		preference_speakers <- rnd( 0.0, 1.0 );
		preference_band <- rnd( 0.0, 1.0 );
		
		preference_props <- rnd( 0.0, 1.0 );
		preference_instruments <- rnd( 0.0, 1.0 );
		preference_vocals <- rnd( 0.0, 1.0 );
		
		crowd_affinity <- rnd( -0.5, 0.5 );
	}
	
	reflex arrivedToStage when:!empty(Stage at_distance (distanceThreshold * 40/numberOfStages)){
		ask Stage at_distance (distanceThreshold * 40/numberOfStages) {
			if(myself.target = self){
				myself.target <- nil;
				myself.watchingAct <- self;
			}
		}
	}
	reflex watchAct{
		if(watchingAct != nil){
			bool nearby <- false;
			loop ag over: agents_at_distance((distanceThreshold * 40/numberOfStages)){
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
		message informFromStage <- (informs at 0);
		if verbose {
			write self.name + ':\treceived inform msg:\t' + informFromStage.contents;
		}
		int i <- 0;
		loop s over: stages{
			if(s = informFromStage.contents[1]){
				stages <- stages - s;
				utility <- utility - utility[i];
			} 
			i <- i+1;
		}
		if !([informFromStage.contents[1]] in stages){
			utility <- utility + [float(informFromStage.contents[0][0]) * float(preference_lightshow) + 
				float(informFromStage.contents[0][1]) * float(preference_speakers) +
				float(informFromStage.contents[0][2]) * float(preference_band) + 
				float(informFromStage.contents[0][3]) * float(preference_props) +
				float(informFromStage.contents[0][4]) * float(preference_instruments) +
				float(informFromStage.contents[0][5]) * float(preference_vocals) 
			];
			stages <- stages + [informFromStage.contents[1]];
		}
		previousTarget <- target;
		target <- stages[index_of(utility, max(utility))];
		
		if(verbose){
			write self.name + ':\t utility:\t' + utility;
			write self.name + ':\t stages:\t' + stages;			
		}
		
		if (target = watchingAct){
			target <- nil;
			if(verbose){
				write self.name + ':\t already at target:\t' + watchingAct;
			}
		}
		else{
			watchingAct <- nil;			
			if(verbose){
				write self.name + ':\t going to stage:\t' + target;
			}
			
//			if(previousTarget != nil){				
//				do start_conversation to:[previousTarget] performative:'inform' contents:['leaving stage']; // protocol:'fipa-cfp'				
//			}
			
			do start_conversation to:[target] performative:'cfp' contents:['going to stage', self]; // protocol:'fipa-cfp'	
			
		}	
		
	}
	
	reflex read_cfp when: !empty(cfps) {
		loop p over: cfps {
			
			float crowd_utility <- crowd_affinity * float(p.contents[0]) * 2;			
			
			int i <- 0;
			loop s over: stages{
				if(s = p.contents[1]){
					stages <- stages - s;
					utility <- utility - utility[i];
				} 
				i <- i+1;
			}
			utility <- utility + [float(p.contents[2][0]) * float(preference_lightshow) + 
				float(p.contents[2][1]) * float(preference_speakers) +
				float(p.contents[2][2]) * float(preference_band) +
				float(p.contents[2][2]) * float(preference_props) +
				float(p.contents[2][2]) * float(preference_instruments) +
				float(p.contents[2][2]) * float(preference_vocals) +
				crowd_utility
			];
			
			stages <- stages + [p.contents[1]];
			
			
			if (target = stages[index_of(utility, max(utility))]){
				if(verbose){
//					write self.name + ':\t still going to stage:\t' + target;
				}
			}
			else if (watchingAct = stages[index_of(utility, max(utility))]){
				if(verbose){
//					write self.name + ':\t staying at stage:\t' + watchingAct;
				}
			}
			else{
				previousTarget <- target;
				target <- stages[index_of(utility, max(utility))];
				if watchingAct != nil{
					watchingAct <- nil;
				}
				if previousTarget != nil{
					do start_conversation to:[previousTarget] performative:'cfp' contents:['leaving stage', self];		
					if(verbose){
						write self.name + "\tleaving stage " + previousTarget + " because of crowd, now going to " + target;
					}
				}
				do start_conversation to:[target] performative:'cfp' contents:['going to stage', self];
			
			}
			
			
			
		}
	}
	
	
	
	
	
	aspect base {
		rgb agentColor <- rgb(round(255*(0.5 - crowd_affinity)),0,round(255*(0.5 + crowd_affinity)));		
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