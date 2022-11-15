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
	
	bool forget <- true;
	
	int infoLimit <- 1;
	
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
    	if (self.hunger <= 0.0){    		
    		if (verbose){
    			write "Hunger for " + self.name + " is now " + self.hunger;
    		}
    		return 0.0;
    	}
    	else{
    		if (verbose){
    			write "Hunger for " + self.name + " is now " + (self.hunger - hungerReduction );
    		}
    		return self.hunger - hungerReduction;
    	}
	}

    float updateThirst{
    	if (self.thirst <= 0.0){  		
    		if (verbose){
    			write "Thirst for " + self.name + " is now " + self.thirst;
    		}
    		return 0.0;
    	}
    	else{
    		if (verbose){
    			write "Thirst for " + self.name + " is now " + (self.thirst - thirstReduction );
    		}
    		return self.thirst - thirstReduction;
    	}
    }
	
	aspect base {
		rgb agentColor <- rgb("green");
		
		if (self.hunger = 0 and self.thirst = 0) {
			agentColor <- rgb("red");
		} else if (self.thirst = 0) {
			agentColor <- rgb("orange");
		} else if (self.hunger = 0) {
			agentColor <- rgb("blueviolet");
		}
		
		draw circle(1) color: agentColor;
	}
	
	reflex move {
		if(target != nil){
			do goto target: target;
		} else{
			if((self.thirst = 0.0 or self.hunger = 0.0) and not infoAvailable){
				do goto target: Info closest_to self;
			}else{
				do wander speed: 5.0 amplitude: 120.0;
			}	
		}
	}
	
	
	reflex reportApproachingToInfo when: (self.thirst = 0.0 or self.hunger = 0.0) and !infoAvailable and !empty(Info at_distance distanceThreshold) {
		ask Info at_distance distanceThreshold {
			
			if forget {
				myself.foodStores <- self.foodStores closest_to(myself,1);
				myself.drinkStores <- self.drinkStores closest_to(myself, 1);
			}
			else {
				myself.foodStores <- self.foodStores closest_to(myself, infoLimit);
				myself.drinkStores <- self.drinkStores closest_to(myself, infoLimit);
			}
			myself.infoAvailable <- true;
			if (verbose){
				write myself.name + " : at info, have the info";
				write myself.foodStores;
				write myself.drinkStores;
			}
		}
	}
	

	reflex gotoFoodStore when: self.target = nil and self.hunger = 0.0 and infoAvailable and length(self.foodStores) > 0 {
		self.target <- self.foodStores closest_to self;
		write self.name + " -> eat at " + self.target.name;
	}
	
	reflex gotoDrinkStore when: self.target = nil and self.thirst = 0.0 and infoAvailable and length(self.drinkStores) > 0 {
		self.target <- self.drinkStores closest_to self;
		write self.name + " -> drink at " + self.target.name;
	}
	
	reflex reportApproachingToStore when: !empty(Store at_distance distanceThreshold) {
		ask Store at_distance distanceThreshold {
			if(myself.hunger = 0.0 and self.hasFood){
				if (verbose){
					write myself.name + " has eaten at " + self.name ;
				}
				myself.hunger <- maxHunger;
				myself.target <- nil;
				if(forget){
					myself.foodStores <- [];
					myself.drinkStores <- [];
					myself.infoAvailable <- false;
				}
			}
			if(myself.thirst = 0.0 and self.hasDrink){
				if (verbose){
					write myself.name + " has drunk at " + self.name ;
				}
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
			self.hasFood <- true;
			self.hasDrink <- true;
		}else{
			if flip(0.5){
				self.hasDrink <- true;
			}else{
				self.hasFood <- true;				
			}
		}
	}

	aspect base {
		rgb agentColor <- rgb("lightgray");
		
		if (self.hasFood and self.hasDrink) {
			agentColor <- rgb("darkgreen");
		} else if (self.hasDrink) {
			agentColor <- rgb("darkorange");
		} else if (self.hasFood) {
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