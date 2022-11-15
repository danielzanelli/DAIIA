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
	int numberOfPeople <- 100;
	int numberOfStores <- 20;
	int distanceThreshold <- 5;	
	
	bool forget <- false;
	
	int infoLimit <- 100;
	int maxHunger <- 400;
	int maxThirst <- 400;
	
	float badChance <- 0.5;
	
	bool verbose <- false;
	
	
	init {
		create Person number:numberOfPeople;
		create Store number:numberOfStores;
		create Info number:1;
		create Guard number:1;

		loop counter from: 1 to: numberOfPeople {
        	Person my_agent <- Person[counter - 1];
        	my_agent <- my_agent.setName(counter);
        }
		
		loop counter from: 1 to: numberOfStores {
        	Store my_agent <- Store[counter - 1];
        	my_agent <- my_agent.setName(counter);
        }

	}
}

species Person skills: [moving] {
		
	
	int hunger <- maxHunger update: updateHunger();
	int thirst <- maxThirst update: updateThirst();
	string personName <- "Undefined";
	bool infoAvailable <- false;	
	Store target;
	Info infoTarget;	
	list foodStores <- [];
	list drinkStores <- [];
	bool bad <- flip(badChance);
	bool dead <- false;
	


	action setName(int num) {
		personName <- "Person " + num;
	}

    int updateHunger{
    	if (hunger <= 0){
    		if(verbose){
    			write "Hunger for person " + personName + " is now " + hunger;    			
			}
    		return 0;
    	}
    	else{
    		//write "Hunger for person " + personName + " is now " + (hunger - 1 );
    		return hunger - 1;
    	}
	}

    int updateThirst{
    	if (thirst <= 0){
    		if(verbose){
    			write "Thirst for person " + personName + " is now " + thirst;
			}
    		return 0;
    	}
    	else{
    		//write "Thirst for person " + personName + " is now " + (thirst - 1 );
    		return thirst - 1;
    	}
    }
	
	aspect base {
		rgb agentColor <- rgb("green");		
		if (self.bad) {
			agentColor <- rgb("black");
		} else if (hunger = 0 and thirst = 0) {
			agentColor <- rgb("red");
		} else if (thirst = 0) {
			agentColor <- rgb("orange");
		} else if (hunger = 0) {
			agentColor <- rgb("blueviolet");
		}		
		draw circle(1) color: agentColor;
	}
	
    reflex beingKilled when: self.dead{
        do die;
    }
	
	reflex move {
		if(target != nil){
			do goto target: target;
		} else{
			if((thirst = 0 or hunger = 0) and not infoAvailable){
				do goto target: Info closest_to self;		
			}else{
				do wander;
			}	
		}
	}
	

	reflex gotoFoodStore when: target = nil and hunger = 0 and infoAvailable{
		if(length(self.foodStores) > 0){
			Store chosen <- self.foodStores closest_to self;
			if(verbose){
				write "Person " + personName + " going to the food store " + chosen;
			}
			target <- chosen;		
		}
	}
	
	reflex gotoDrinkStore when: target = nil and thirst = 0 and infoAvailable{
		if(length(self.drinkStores) > 0){
			Store chosen <- self.drinkStores closest_to self;
			if(verbose){
				write "Person " + personName + " going to the drink store " + chosen;
			}
			target <- chosen;			
		}
	}
	
	reflex reportApproachingToStore when: !empty(Store at_distance distanceThreshold) {
		ask Store at_distance distanceThreshold {
			if(myself.hunger = 0 and self.hasFood){
				if(verbose){
					write myself.personName + " has eaten at " + self.storeName ;
				}
				myself.hunger <- maxHunger;
				myself.target <- nil;
				if(forget){
					myself.foodStores <- [];
					myself.drinkStores <- [];
					myself.infoAvailable <- false;
				}
			}
			if(myself.thirst = 0 and self.hasDrink){
				if(verbose){
					write myself.personName + " has drank at " + self.storeName ;
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
	
	reflex reportApproachingToInfo when: !empty(Info at_distance distanceThreshold) {
		if(hunger = 0 or thirst = 0){
			ask Info at_distance distanceThreshold {
				myself.foodStores <- self.foodStores closest_to(myself, infoLimit);
				myself.drinkStores <- self.drinkStores closest_to(myself, infoLimit);
				myself.infoAvailable <- true;
			}
		}
	}
}


species Info{	
	
	list foodStores <- Store at_distance 100000 where each.hasFood;
	list drinkStores <- Store at_distance 100000 where each.hasDrink;
	list targetQueue <- [];	
	list targetGiven <- [];
	
	Guard guard <- Guard closest_to self;
	
	aspect base {	
		draw square(5) color: rgb("black");
	}
	
	reflex callGuard when: length(targetQueue) > 0{		
		guard.called <- true;
	}
	
	reflex reportApproachingPerson when: !empty(Person at_distance distanceThreshold) {
		ask Person at_distance distanceThreshold {
			if(self.hunger = 0 or self.thirst = 0){
				if(self.bad and !(self in myself.targetQueue) and !(self in myself.targetGiven)){
					write "Bad person detected at Info";
					myself.guard <- Guard closest_to myself;
					myself.targetQueue <- myself.targetQueue + [self];
					if(verbose){
						write "Sent:\t" + myself.guard;
						write "Total detected:\t" + (length(myself.targetQueue) + length(myself.targetGiven) );
					}
				}				
			}			
		}
	}
	
}


species Guard skills: [moving] {	
	
	list targetList <- [];
	Person currentTarget <- nil;
	bool called <- false;
	Info infoPlace <- Info closest_to self;
		
	
	aspect base {	
		draw triangle(5) color: rgb("blue");
	}
	
	
	reflex reportApproachingToInfo when: !empty(Info at_distance distanceThreshold) {
		if(called and length(targetList) = 0){
			ask Info at_distance distanceThreshold {
				myself.targetList <- self.targetQueue;
				self.targetGiven <- self.targetGiven + self.targetQueue;
				self.targetQueue <- [];
				myself.currentTarget <- myself.targetList[0];
				myself.called <- false;
				if(verbose){
					write "New targets:\t" + myself.targetList;
					write "Given targets:\t" + self.targetGiven;
				}
			}			
		}
	}
	
	reflex reportApproachingTarget when: !empty(Person at_distance distanceThreshold){
		if(currentTarget != nil){
			ask Person at_distance distanceThreshold {
				if(myself.currentTarget = self){	
									
					write "Killed target:\t" + self;
					
					self.dead <- true;
					
					// Remove first element from the target list
					myself.targetList <- myself.targetList - myself.targetList[0];
					
					//If there are remaining targets
					if(length(myself.targetList)>0){							
						myself.currentTarget <- myself.targetList[0];
						
					}else{
						// Just caught last target
						myself.currentTarget <- nil;
					}
				}
			}
		}
	}
	
	reflex move {
		self.speed <- 0.5;
		//write targetList;
		if(currentTarget != nil){
			//write "going to target:\t" + currentTarget;
			do goto target: currentTarget;
		} else{
			if(called){
				//write "going to info:\t" + infoPlace;
				do goto target: infoPlace;		
			}else{
				//write "wandering";
				do wander;
			}
		}
	}
	
	
}


species Store {

	bool hasFood <- false;
	bool hasDrink <- false;	
	string storeName <- "Undefined";
	
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
	

	action setName(int num) {
		storeName <- "Store " + num;
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



experiment myAssignment type:gui {
	
	parameter "numberOfPeople" category: "Agents" var:numberOfPeople;
	parameter "numberOfStores" category: "Agents" var:numberOfStores;
	parameter "distanceThreshold" var:distanceThreshold;	
	
	parameter "forget" var:forget;
	
	parameter "infoLimit" var:infoLimit min:0 max:numberOfStores;
	
	parameter "maxHunger" var:maxHunger;
	
	parameter "maxThirst" var:maxThirst;
	
	parameter "badChance" var:badChance;
	
	parameter "verbose" var: verbose;
	
	
	output {
		display myDisplay {
			species Guard aspect:base;
			species Info aspect:base;
			species Person aspect:base;
			species Store aspect:base;
		}
	}
}