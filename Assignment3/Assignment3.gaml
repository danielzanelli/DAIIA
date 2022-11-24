/**
* Name: Assignment3
* Based on the internal empty template. 
* Author: Daniel, Medhi 
* Tags: 
*/


model Assignment3


global {
	
	int numberOfQueens <- 12;

	init {
		int index <- 0;
		create Queen number: numberOfQueens;
		
		loop counter from: 1 to: numberOfQueens {
        	Queen queen <- Queen[counter - 1];
        	queen <- queen.setId(index);
        	queen <- queen.initializeCell();
        	index <- index + 1;
        }
	}
}


species Queen skills: [fipa]{
    
	ChessBoard myCell; 
	int id; 
	int index <- 0;
       
    reflex updateCell {
    	write('id' + id);
    	write('X: ' + myCell.grid_x + ' - Y: ' + myCell.grid_y);
    	myCell <- ChessBoard[myCell.grid_x,  mod(index, numberOfQueens)];
    	location <- myCell.location;
    	index <- index + 1;
    }

	action setId(int input) {
		id <- input;
	}
	
	action initializeCell {
		myCell <- ChessBoard[id, id];
	}
	
	float size <- 30/numberOfQueens;
	
	aspect base {
        draw circle(size) color: #blue ;
       	location <- myCell.location ;
    }

}

species Stage {
	
}

species Person skills: [moving]{
	
	float preference_lightshow;
	float preference_speakers;
	float preference_band;
	
	Stage target <- nil;
	
	aspect base {
		rgb agentColor <- rgb("purple");		
		draw circle(1) color: agentColor;
	}
	
	reflex move {
		if(target != nil){
			do goto target: target;
		} else{
			do wander;
		}
	}
}
    
    
grid ChessBoard width: numberOfQueens height: numberOfQueens { 
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
			species Queen aspect: base;
		}
	}
}