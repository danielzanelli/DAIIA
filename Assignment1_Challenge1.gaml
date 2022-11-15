/**
* Name: Assignment1_Challenge1
* Based on the internal empty template. 
* Author: Mehdi, Daniel
* Tags: 
*/


model Assignment1_Challenge1

/* Insert your model definition here */

global {
	
	// PARAMETERS
	
	// Weather or not to print on screen
	bool verbose <- false;

	// Number of instances
	int numberOfPeopleWithMemory <- 20;
	int numberOfPeopleWithoutMemory <- 20;
	int numberOfStores <- 10;
	
	// Distance to consider to be "inside" location
	int distanceThreshold <- 1;
	
	// forget stores you have eat
//	bool forget <- false;
	
	// Number of locations given by Info center
	int infoLimit <- 5;
	
	// Amount of points before considered hungry/thirsty (0-> need to eat/drink; 100-> fully satisfied)
	float maxHunger <- 100.0;
	float hungerReduction <- 1.0;
	
	float maxThirst <- 100.0;
	float thirstReduction <- 1.0;
	
	// Speed of Person when wandering v/s when going to a target
	float targetSpeed <- 1.0;
	float wanderSpeed <- 1.0;
	
	float exploitVSexplore <- 0.5;
	
	// METRICS (quantify distance traveled depending if agents have or dont have memory)
	// (time  step considered as 1 and distance traveled proportional to speed)
	float distanceMemory <- 0.0;
	float distanceNoMemory <- 0.0;
	
	init {
		create Person with:[forget::false]  number:numberOfPeopleWithMemory;
		create Person with:[forget::true]  number:numberOfPeopleWithoutMemory;
		create Store number:numberOfStores;
		create Info number:1;
	}
}

species Person skills: [moving] {
		
	bool forget;
	float hunger <- maxHunger update: updateHunger();
	float thirst <- maxThirst update: updateThirst();
	bool infoAvailable <- false;
	Store target;
	list foodStores <- [];
	list hasEatenThere <- [];
	list drinkStores <- [];
	list hasDrunkThere <- [];

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
		if(self.target != nil){
			self.speed <- targetSpeed;
			if(self.forget){
				distanceNoMemory <- distanceNoMemory + self.speed / numberOfPeopleWithoutMemory;
			}else{
				distanceMemory <- distanceMemory + self.speed / numberOfPeopleWithMemory;
			}
			do goto target: self.target;
		} else{
			if((self.thirst = 0 or self.hunger = 0) and not self.infoAvailable){
				self.speed <- targetSpeed;
				if(self.forget){
					distanceNoMemory <- distanceNoMemory + self.speed / numberOfPeopleWithoutMemory;
				}else{
					distanceMemory <- distanceMemory + self.speed / numberOfPeopleWithMemory;
				}
				do goto target: Info closest_to self;
			}else{
				do wander speed: 5.0 amplitude: 120.0;
			}	
		}
		write "Average distance walked without memory:\t" + distanceNoMemory;
		write "Average distance walked with memory:\t" + distanceMemory;
	}
	
	reflex reportApproachingToInfo when: (self.thirst = 0.0 or self.hunger = 0.0) and !self.infoAvailable and !empty(Info at_distance distanceThreshold) {
		ask Info at_distance distanceThreshold {
			if myself.forget {
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

	reflex gotoFoodStoreNoMem when: self.target = nil and self.hunger = 0.0 and self.infoAvailable and self.forget {
		self.target <- self.foodStores closest_to self;
		write self.name + " -> eat at " + self.target.name;
	}
	
	reflex gotoDrinkStoreNoMem when: self.target = nil and self.thirst = 0.0 and self.infoAvailable and self.forget{
		self.target <- self.drinkStores closest_to self;
		write self.name + " -> drink at " + self.target.name;
	}
	
	reflex feelHungryWithMem when: self.target = nil and self.hunger = 0.0 and self.infoAvailable and !self.forget {
		if (length(self.hasEatenThere) <= 0){
				self.target <- self.foodStores closest_to self;
				write self.name + " -> exploit info -> 1st-time eat at " + self.target.name;
			}
		else {
			// exploration vs exploitation
			if flip(exploitVSexplore){
				self.target <- self.hasEatenThere closest_to self;
				write self.name + " -> exploit memory-> eat again at " + self.target.name;
			}
			else{
				self.target <- 1 among self.foodStores at 0;
				write self.name + " -> eat & explore at " + self.target.name;
			}
		}
	}
	
	reflex feelThirstyWithMem when: self.target = nil and self.thirst = 0.0 and self.infoAvailable and !self.forget {
		if (length(self.hasDrunkThere) <= 0){
				self.target <- self.drinkStores closest_to self;
				write self.name + " -> exploit info -> 1st-time drink at " + self.target;	
		}
		else {
			// exploration vs exploitation
			if (flip(exploitVSexplore)) {
				self.target <- self.hasDrunkThere closest_to self;
				write self.name + " -> exploit memory-> drink again at " + self.target;
			}
			else{
				self.target <- 1 among self.drinkStores at 0;
				write self.name + " -> drink & explore at " + self.target;
			}
		}
	}
	
	reflex reportApproachingToStore when: !empty(Store at_distance distanceThreshold) {
		ask Store at_distance distanceThreshold {
			if(myself.hunger = 0.0 and self.hasFood){
				if (verbose){
					write myself.name + " has eaten at " + self.name ;
				}
				myself.hunger <- maxHunger;
				myself.target <- nil;
				if(myself.forget){
					myself.foodStores <- [];
					myself.drinkStores <- [];
					myself.infoAvailable <- false;
				}
				else {
					myself.hasEatenThere <- myself.hasEatenThere + self;
				}
			}
			if(myself.thirst = 0.0 and self.hasDrink){
				if (verbose){
					write myself.name + " has drunk at " + self.name ;
				}
				myself.thirst <- maxThirst;
				myself.target <- nil;
				if(myself.forget){
					myself.foodStores <- [];
					myself.drinkStores <- [];
					myself.infoAvailable <- false;
				}
				else {
					myself.hasDrunkThere <- myself.hasDrunkThere + self;
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
	parameter "numberOfPeopleWithMemory" category: "Agents" var:numberOfPeopleWithMemory;
	parameter "numberOfPeopleWithoutMemory" category: "Agents" var:numberOfPeopleWithoutMemory;
	
	
	parameter "numberOfStores" category: "Agents" var:numberOfStores;
	parameter "distanceThreshold" var:distanceThreshold;	
	
//	parameter "forget" var:forget;
	
	parameter "infoLimit" var:infoLimit min:0 max:numberOfStores;
	
	parameter "exploitVSexplore" var: exploitVSexplore min:0.0 max:1.0;
	
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