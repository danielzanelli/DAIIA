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
	
	// Weather or not to print on screen
	bool verbose <- false;

	// Number of instances
	int numberOfPeopleWithMemory <- 20;
	int numberOfPeopleWithoutMemory <- 20;
	int numberOfStores <- 5;
	
	// Distance to consider to be "inside" location
	int distanceThreshold <- 1;
	
	// Number of locations given by Info center
	int limit <- 10;
	
	// Amount of points before considered hungry/thirsty (0-> need to eat/drink; 100-> fully satisfied)
	int maxHunger <- 100;
	int maxThirst <- 100;
	
	// Speed of Person when wandering v/s when going to a target
	float targetSpeed <- 1.0;
	float wanderSpeed <- 1.0;
	
	// METRICS (quantify distance traveled depending if agents have or dont have memory)
	// (time  step considered as 1 and distance traveled proportional to speed)
	float distanceMemory <- 0.0;
	float distanceNoMemory <- 0.0;
	
	init {
		create Person with:[forget::false]  number:numberOfPeopleWithMemory;
		create Person with:[forget::true]  number:numberOfPeopleWithoutMemory;
		create Person number:numberOfPeopleWithoutMemory;
		create Store number:numberOfStores;
		create Info number:1;
		

		loop counter from: 1 to: numberOfPeopleWithMemory + numberOfPeopleWithoutMemory {
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
		
	bool forget;
	int hunger <- maxHunger update: updateHunger();
	int thirst <- maxThirst update: updateThirst();
	string personName <- "Undefined";
	bool infoAvailable <- false;	
	Store target;
	Info infoTarget;	
	list foodStores <- [];
	list drinkStores <- [];
	


	action setName(int num) {
		personName <- "Person " + num;
	}

    int updateHunger{
    	if (hunger <= 0){
    		if (verbose){
    			write "Hunger for person " + personName + " is now " + hunger;
    		}
    		return 0;
    	}
    	else{
    		if (verbose){
    			write "Hunger for person " + personName + " is now " + (hunger - 1 );
			}
    		return hunger - 1;
    	}
	}

    int updateThirst{
    	if (thirst <= 0){
    		if (verbose){
    			write "Thirst for person " + personName + " is now " + thirst;
    		}
    		return 0;
    	}
    	else{
    		if (verbose){
    			write "Thirst for person " + personName + " is now " + (thirst - 1 );
    		}
    		return thirst - 1;
    	}
    }
	
	aspect base {
		rgb agentColor <- rgb("green");
		
		if (hunger = 0 and thirst = 0) {
			agentColor <- rgb("red");
		} else if (thirst = 0) {
			agentColor <- rgb("darkorange");
		} else if (hunger = 0) {
			agentColor <- rgb("purple");
		}
		
		draw circle(1) color: agentColor;
	}
	
	reflex move {
		if(target != nil){
			self.speed <- targetSpeed;
			if(self.forget){
				distanceNoMemory <- distanceNoMemory + self.speed / numberOfPeopleWithoutMemory;
			}else{
				distanceMemory <- distanceMemory + self.speed / numberOfPeopleWithMemory;
			}
			do goto target: target;
		} else{
			if((thirst = 0 or hunger = 0) and not infoAvailable){
				self.speed <- targetSpeed;
				if(self.forget){
					distanceNoMemory <- distanceNoMemory + self.speed / numberOfPeopleWithoutMemory;
				}else{
					distanceMemory <- distanceMemory + self.speed / numberOfPeopleWithMemory;
				}
				do goto target: Info closest_to self;
			}else{
				//self.speed <- wanderSpeed;		
				//if(self.forget){
				//	distanceNoMemory <- distanceNoMemory + self.speed / numberOfPeopleWithoutMemory;
				//}else{
				//	distanceMemory <- distanceMemory + self.speed / numberOfPeopleWithMemory;
				//}
				do wander;
			}	
		}
		write "Average distance walked forgetting locations:\t" + distanceNoMemory;
		write "Average distance walked remembering locations:\t" + distanceMemory;
	}
	

	reflex gotoFoodStore when: target = nil and hunger = 0 and infoAvailable{
		if(length(self.foodStores) > 0){
			Store chosen <- self.foodStores closest_to self;			
    		if (verbose){
				write "Person " + personName + " going to the food store " + chosen;
			}
			target <- chosen;		
		}
	}
	
	reflex gotoDrinkStore when: target = nil and thirst = 0 and infoAvailable{
		if(length(self.drinkStores) > 0){
			Store chosen <- self.drinkStores closest_to self;
    		if (verbose){
				write "Person " + personName + " going to the drink store " + chosen;
			}
			target <- chosen;			
		}
	}
	
	reflex reportApproachingToStore when: !empty(Store at_distance distanceThreshold) {
		ask Store at_distance distanceThreshold {
			if(myself.hunger = 0 and self.hasFood){
				
    			if (verbose){
					write myself.personName + " has eaten at " + self.storeName ;
				}
				myself.hunger <- maxHunger;
				myself.target <- nil;
				if(myself.forget){
					myself.foodStores <- [];
					myself.drinkStores <- [];
					myself.infoAvailable <- false;
				}
			}else if(myself.thirst = 0 and self.hasDrink){				
    			if (verbose){
					write myself.personName + " has drank at " + self.storeName ;
				}
				myself.thirst <- maxThirst;
				myself.target <- nil;
				if(myself.forget){
					myself.foodStores <- [];
					myself.drinkStores <- [];
					myself.infoAvailable <- false;
				}
			}
		}
	}

	
	reflex reportApproachingToInfo when: !empty(Info at_distance distanceThreshold) {
		ask Info at_distance distanceThreshold {
			
			myself.foodStores <- copy_between(self.foodStores, 0, limit);
			myself.drinkStores <- copy_between(self.drinkStores, 0, limit);
			myself.infoAvailable <- true;
			
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
		} else if (hasFood) {
			agentColor <- rgb("skyblue");
		} else if (hasDrink) {
			agentColor <- rgb("brown");
		}
		
		draw square(2) color: agentColor;
	}
}



experiment myAssignment type:gui {
	output {
		display myDisplay {
			species Info aspect:base;
			species Person aspect:base;
			species Store aspect:base;
		}
	}
}