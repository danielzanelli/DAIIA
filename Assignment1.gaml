/**
* Name: Assignment1
* Based on the internal empty template. 
* Author: Daniel, Mehdi
* Tags: 
*/


model Assignment1

/* Insert your model definition here */


global {
	int numberOfPeople <- 30;
	int numberOfStores <- 5;
	int distanceThreshold <- 1;
	
	bool forget <- false;
	
	init {
		create Person number:numberOfPeople;
		create Store number:numberOfStores;
		create Info number:1;
		
				
		// ------------------ START OF THE NEW PART ------------------
		loop counter from: 1 to: numberOfPeople {
        	Person my_agent <- Person[counter - 1];
        	my_agent <- my_agent.setName(counter);
        }
		
		loop counter from: 1 to: numberOfStores {
        	Store my_agent <- Store[counter - 1];
        	my_agent <- my_agent.setName(counter);
        }
        // ------------------ END OF THE NEW PART ------------------   
	}
}

species Person skills: [moving] {

	string personName <- "Undefined";
	int hunger <- 1000 update: updateHunger();
	int thirst <- 1000 update: updateThirst();
	
	bool infoAvailable <- false;
	
	Store target;
	Info infoTarget;
	
	list foodStores <- [];
	list drinkStores <- [];
	


	action setName(int num) {
		personName <- "Person " + num;
	}

    int updateHunger{
    	//write "Updating " + personName;
    	if (hunger <= 0){    		
    		//if(infoAvailable and target = nil){
    		//	target <- 
    		//}
    		write "Hunger for person " + personName + " is now " + hunger;
    		return 0;
    	}
    	else{
    		write "Hunger for person " + personName + " is now " + (hunger - 1 );
    		return hunger - 1;
    	}
	}

    int updateThirst{
    	//write "Updating " + personName;
    	if (thirst <= 0){    		
    		//if(infoAvailable and target = nil){
    		//	target <- 
    		//}
    		write "Thirst for person " + personName + " is now " + thirst;
    		return 0;
    	}
    	else{
    		write "Thirst for person " + personName + " is now " + (thirst - 1 );
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
			write "Person " + personName + " going to the food store " + chosen;
			target <- chosen;		
		}
	}
	
	reflex gotoDrinkStore when: target = nil and thirst = 0 and infoAvailable{
		if(length(self.drinkStores) > 0){
			Store chosen <- self.drinkStores closest_to self;
			write "Person " + personName + " going to the drink store " + chosen;
			target <- chosen;			
		}
	}
	
	reflex reportApproachingToStore when: !empty(Store at_distance distanceThreshold) {
		ask Store at_distance distanceThreshold {
			if(myself.hunger = 0 and self.hasFood){
				write myself.personName + " has eaten at " + self.storeName ;
				myself.hunger <- 1000;
				myself.target <- nil;
				if(forget){
					myself.foodStores <- [];
					myself.drinkStores <- [];
					myself.infoAvailable <- false;
				}
			}else if(myself.thirst = 0 and self.hasDrink){
				write myself.personName + " has drank at " + self.storeName ;
				myself.thirst <- 1000;
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
		ask Info at_distance distanceThreshold {
			
			myself.foodStores <- copy_between(self.foodStores, 0, self.limit);
			myself.drinkStores <- copy_between(self.drinkStores, 0, self.limit);
			myself.infoAvailable <- true;
			
		}
	}

}


species Info{
	
	int limit <- 1;
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