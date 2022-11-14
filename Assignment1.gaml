/**
* Name: Assignment1
* Based on the internal empty template. 
* Authors: Daniel, Mehdi
* Tags: 
*/


model Assignment1

/* Insert your model definition here */


global {
	
	// PARAMETERS
	int numberOfPeople <- 30;
	int numberOfStores <- 6;
	int distanceThreshold <- 1;
	
	bool forget <- false;
	
	int infoLimit <- 3;
	
	float maxHunger <- 100.0;
	float hungerReduction <- 1.0;
	
	float maxThirst <- 100.0;
	float thirstReduction <- 1.0;
	
	bool verbose <- true;
	
	
	init {
		create Person number:numberOfPeople;
		create Store number:numberOfStores;
		create Info number:1;
		

/* 		loop counter from: 1 to: numberOfPeople {
        	Person my_agent <- Person[counter - 1];
        	my_agent <- my_agent.setName(counter);
        }
		
		loop counter from: 1 to: numberOfStores {
        	Store my_agent <- Store[counter - 1];
        	my_agent <- my_agent.setName(counter);
        }*/

	}
}

species Person skills: [moving] {
		
	
	//OTHER ATTRIBUTES
	float hunger <- maxHunger min: 0.0 update: updateHunger();
	float thirst <- maxThirst min: 0.0 update: updateThirst();
	// string personName <- "Undefined";
	bool infoAvailable <- false;	
	Store target;
	list foodStores <- [];
	list drinkStores <- [];

    float updateHunger{
    	//write "Updating " + personName;
    	if (hunger <= 0.0){    		
    		if (verbose){
    			write "Hunger for " + name + " is now " + hunger;
    		}
    		return 0.0;
    	}
    	else{
    		if (verbose){
    			write "Hunger for " + name + " is now " + (hunger - hungerReduction );
    		}
    		return hunger - hungerReduction;
    	}
	}

    float updateThirst{
    	//write "Updating " + personName;
    	if (thirst <= 0.0){  		
    		if (verbose){
    			write "Thirst for " + name + " is now " + thirst;
    		}
    		return 0.0;
    	}
    	else{
    		if (verbose){
    			write "Thirst for " + name + " is now " + (thirst - thirstReduction );
    		}
    		return thirst - thirstReduction;
    	}
    }
	
	aspect base {
		rgb agentColor <- rgb("green");
		
		if (hunger = 0 and thirst = 0) {
			agentColor <- rgb("red");
		} else if (thirst = 0) {
			agentColor <- rgb("orange");
		} else if (hunger = 0) {
			agentColor <- rgb("blueviolet");
		}
		
		draw circle(1) color: agentColor;
	}
	
	reflex move {
		if(target != nil){
			do goto target: target;
		} else{
			if((thirst = 0.0 or hunger = 0.0) and not infoAvailable){
				do goto target: Info closest_to self;
			}else{
				do wander;
			}	
		}
	}
	
	
	reflex reportApproachingToInfo when: (thirst = 0.0 or hunger = 0.0) and !infoAvailable and !empty(Info at_distance distanceThreshold) {
		ask Info at_distance distanceThreshold {
			
			myself.foodStores <- self.foodStores closest_to(myself, infoLimit);
			myself.drinkStores <- self.drinkStores closest_to(myself, infoLimit);
			myself.infoAvailable <- true;
			if (verbose){
				write myself.name + " : at info, have the info";
				write myself.foodStores;
				write myself.drinkStores;
			}
		}
	}
	

	reflex gotoFoodStore when: target = nil and hunger = 0.0 and infoAvailable and length(self.foodStores) > 0 {
		Store chosen <- self.foodStores closest_to self;
		write name + " going to the food store " + chosen;
		target <- chosen;

	}
	
	reflex gotoDrinkStore when: target = nil and thirst = 0.0 and infoAvailable and length(self.drinkStores) > 0 {
		Store chosen <- self.drinkStores closest_to self;
		write name + " going to the drink store " + chosen;
		target <- chosen;
	}
	
	reflex reportApproachingToStore when: !empty(Store at_distance distanceThreshold) {
		ask Store at_distance distanceThreshold {
			if(myself.hunger = 0.0 and self.hasFood){
				write myself.name + " has eaten at " + self.name;
				myself.hunger <- maxHunger;
				myself.target <- nil;
				if(forget){
					myself.foodStores <- [];
					myself.drinkStores <- [];
					myself.infoAvailable <- false;
				}
			}
			if(myself.thirst = 0.0 and self.hasDrink){
				write myself.name + " has drank at " + self.name ;
				myself.thirst <- maxThirst;
				myself.target <- nil;
				if(forget){
					myself.foodStores <- [];
					myself.drinkStores <- [];
					myself.infoAvailable <- false;
				}
			}				
		
		}
	}
}


species Info{	
	
	list foodStores <- Store at_distance 100000 where each.hasFood;
	list drinkStores <- Store at_distance 100000 where each.hasDrink;
	
	
	aspect base {	
		draw square(5) color: rgb("black");
	}
	
	
}

species Store {

	bool hasFood <- false;
	bool hasDrink <- false;
	
	//Initialize with probability 1/3 'has drinks', 1/3 'has food' and 1/3 'has both'	
	init{		
		if (flip(0.333)){
			hasFood <- true;
			hasDrink <- true;
		}else{
			if flip(0.5){
				hasDrink <- true;
			}else{
				hasFood <- true;				
			}
		}
	}

	aspect base {
		rgb agentColor <- rgb("lightgray");
		
		if (hasFood and hasDrink) {
			agentColor <- rgb("darkgreen");
		} else if (hasDrink) {
			agentColor <- rgb("darkorange");
		} else if (hasFood) {
			agentColor <- rgb("purple");
		}
		
		draw square(2) color: agentColor;
	}
}



experiment gui_experiment type:gui {
	parameter "numberOfPeople" category: "Agents" var:numberOfPeople;
	parameter "numberOfStores" category: "Agents" var:numberOfStores;
	parameter "distanceThreshold" var:distanceThreshold;	
	
	parameter "forget" var:forget;
	
	parameter "infoLimit" var:infoLimit min:0 max:numberOfStores;
	
	parameter "maxHunger" var:maxHunger;
	parameter "hungerReduction" var: hungerReduction max:maxHunger;
	
	parameter "maxThirst" var:maxThirst;
	parameter "thirstReduction" var: thirstReduction max:maxThirst;
	
	parameter "verbose" var: verbose;
	
	output {
		display myDisplay {
			species Info aspect:base;
			species Person aspect:base;
			species Store aspect:base;
		}
	}
}
