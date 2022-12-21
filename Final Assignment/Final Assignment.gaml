/**
* Name: Assignment3
* Based on the internal empty template. 
* Author: Daniel, Medhi 
* Tags: 
*/


model Final_Assignment


global {
	

	int numberOfPeople <- 50;
	
	float distanceThreshold <- 10.0;	

	bool verbose <- true;
	
	list types <- ["type1","type2","type3","type4","type5"];

	init {
		create Person number: numberOfPeople;

	}
}


species Person skills: [moving,  fipa]{
	
	float trait_1;
	float trait_2;
	float trait_3;
	
	string type;
	
	float global_value;

	
	init{
		
		type <-types[rnd(length(types)-1)];
		
		trait_1 <- rnd( 0.0, 1.0 );
		trait_2 <- rnd( 0.0, 1.0 );
		trait_3 <- rnd( 0.0, 1.0 );

	}
	
	
	reflex read_cfp when: !empty(cfps) {
		loop p over: cfps {
			
			write 'read cfp';
		}
	}
	
	
	
	
	
	aspect base {
		rgb agentColor;
		
		if type = "type1"{
			agentColor <- rgb('red');			
		}
		else if type = "type2"{
			agentColor <- rgb('blue');
		}
		else if type = "type3"{
			agentColor <- rgb('green');
		}
		else if type = "type4"{
			agentColor <- rgb('yellow');
		}
		else if type = "type5"{
			agentColor <- rgb('black');
		}
		else{
			agentColor <- rgb('white');
		}
		draw circle(1) color: agentColor;
	}
	
	reflex move {
		do wander;
	}
}
    
    

experiment Final_Assignment type: gui{	

	parameter "People" category: "Agents" var:numberOfPeople;
	parameter "Distance Threshold" category: "Agents"  var:distanceThreshold;
	parameter "Verbose" category: "Agents" var: verbose;
	
	output{
		display Person{
			species Person aspect: base;
		}
	}
}