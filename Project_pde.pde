// **CS171 PROJECT**

// Importing the Sound File
import ddf.minim.*;
Minim minim;
AudioPlayer jingle;

// Variable Storage
PImage ocean, player, fish, bottle1, bag, foodWrapper, oxygen;

// Initializes the Variables
int player_x = 600, player_y = 360; // Initial pos. of the player
int score = 0, fuel = 25; // Player's score and fuel/oxygen
int direction = 1; // 0 for right, 1 for left
int frame = 1; // Sprite sheet frame
int skip = 0;
int fishCollisionTimer = 0; // Timer for fish collision message

boolean rightKeyPressed = false; // Indicates & flags for when the right arrow key event is triggered
boolean leftKeyPressed = false; // Indicates & flags for when the left arrow key event is triggered
boolean upKeyPressed = false; // Indicates & flags for when the up arrow key event is triggered
boolean downKeyPressed = false; // Indicates & flags for when the down arrow key event is triggered
boolean fishCollision = false; // Flag to indicate fish collision

boolean gameover = false; // Flag to indicate if the game is over
boolean restartButtonPressed = false; //flag to see if the restart button was pressed
boolean gameStarted = false; // Flag to track whether the game has started
boolean introScreen = true; // Flag to track whether the game is on the intro screen

ArrayList<Obstacle> obstacles = new ArrayList<Obstacle>(); // List to store obstacles

class Obstacle {
  PImage img; // image for obstacles
  float x, y, speed;

  // Constructor to initialise an obstacle
  Obstacle(PImage img, float speed) {
    this.img = img; // obstacle's image
    this.speed = speed; // obstacle's speed
    respawn(); // respawn() method to set the initial position
  }

  // method to reset and respawn position of the obstacle to any random pos.
  void respawn() {
    x = random(width); // x becomes a random value within the width of the screen
    y = -100;
  }

  void display() {
    pushMatrix();
    translate(x, y);
    rotate(frameCount / 10.0); // rotates the obstacle
    image(img, -30, -30, 75, 75); // dimensions of the obstacle
    popMatrix();
  }

  void update() {
    y += speed; // moves obstacle down the screen depending on its speed
    if (y > height) {
      respawn(); // essentially, if the obstacle leaves the screen respawn it again above the screen
    }
  }

  boolean collidesWithPlayer() {
    float distance = dist(x, y, player_x + 62, player_y + 62);
    return distance < 30;
  }
}

// Sets up the game and initial config.
void setup() {
  size(1448, 724, P2D); // size of canvas

  minim = new Minim(this);
  jingle = minim.loadFile("silver.mp3"); // to load and loop the background music
  jingle.loop();

  // Loads the images for the game from the data folder
  ocean = loadImage("ocean.jpg");
  player = loadImage("scubadiver.png");
  fish = loadImage("fish.png");
  bottle1 = loadImage("bottle1.png");
  bag = loadImage("bag.png");
  foodWrapper = loadImage("foodwrapper.png");
  oxygen = loadImage("oxygen.png");

  // Initializes the obstacles and their configuration with their speed, image
  obstacles.add(new Obstacle(fish, 3)); // fish moves faster than others (3)
  obstacles.add(new Obstacle(bottle1, 2));
  obstacles.add(new Obstacle(bag, 2.5));
  obstacles.add(new Obstacle(foodWrapper, 2));
  obstacles.add(new Obstacle(oxygen, 2));

  textureMode(NORMAL); // Scale texture Top right (0,0) to (1,1)
  blendMode(BLEND); // States how to mix a new image with the one behind it
  noStroke(); // Don't draw lines around objects
}


// Display the intro screen
void drawIntroScreen() {
  background(112, 162, 250); // Solid color background
  fill(255); // White text color
  textAlign(CENTER, CENTER);
  textFont(createFont("VeraMono.ttf", 70)); //downloaded VeraMono font, added it to data folder, and this is the font being used in the font rather than the default font
  text("Ocean Explore", width / 2, height / 2 - 50); // Replace with your game name
  textSize(20);
  fill(87, 87, 87); // Dark grey text color
  text("- Collect as many plastics as possible\n- If the oxygen runs out, and fuel depletion occurs, the game will end\n - Collect oxygen tanks to refill your fuel\n- If your score goes below 0, the game will end\n- Collecting marine life and overfishing will reduce your score, so watch out!", width / 2, height / 2 + 80);
  text("Press any key to start", width / 2, height / 2 + 190);
}


void draw() {
  if (introScreen) {
    drawIntroScreen();
  } else {
    background(ocean);

    if (!gameover) {
      handlePlayer();
      handleObstacles();
      checkCollisions();
      updateScore();

        // checks conditions for the game being over
        if (fuel <= 0 || score < 0) {
          gameover = true;
        }
  
          // Display warning message if there is a fish collision
          if (fishCollision) {
            displayFishWarning();
            fishCollisionTimer++;
    
            // If the timer reaches a certain frame count (e.g., 300 frames = 5 seconds), reset the flag and timer
            if (fishCollisionTimer > 300) {
              fishCollision = false;
              fishCollisionTimer = 0;
            }
          }
        } 
       else {
         displayGameOver(); // if the game is over, it displays the game over message
         displayRestartButton(); // restart button if the game is over
       }
     }
   }


// For all handling of the player and movements
void handlePlayer() {
  pushMatrix();
  translate(player_x, player_y);

  // taken from lab3 and adjusted to help with moving the player and sprite sheet
  float left = (float)((frame % 4)) / 4;
  float right = (float)(((frame % 4) + 1)) / 4;
  float top = (1.0 / 3.0) * ((float)(frame / 4) + 1.0);
  float bottom = (1.0 / 3.0) * ((float)(frame / 4));

  if (direction == 1) {
    float temp = left;
    left = right;
    right = temp;
  }

  beginShape();
  texture(player);
  vertex(0, 0, left, bottom);
  vertex(124, 0, right, bottom);
  vertex(124, 62, right, top);
  vertex(0, 62, left, top);
  endShape(CLOSE);
  popMatrix();

  skip++;
  if (skip > 6) {
    skip = 0;
    frame++;
    if (frame > 5)
      frame = 0;
  }

  // Move player
  if (rightKeyPressed && player_x < width - 62) {
    direction = 0;
    player_x += 3; // Changes how fast the player is moving across (right)
  } else if (leftKeyPressed && player_x > 0) {
    direction = 1;
    player_x -= 3; // Changes how fast the player is moving across (left)
  }

  if (upKeyPressed && player_y > 0) {
    player_y -= 2; // Changes how fast the player is moving up
  } else if (downKeyPressed && player_y < height - 62) {
    player_y += 2; // Changes how fast the player is moving down
  }
}

void handleObstacles() {
  // iterate through all obstacles & update & display the obstacles
  for (Obstacle obstacle : obstacles) {
    obstacle.update();
    obstacle.display();
  }

  // for every 100 frames, reduce the fuel
  if (frameCount % 100 == 0) {
    fuel--;
  }
}

// checks for collisions between player and obstacles and acts based on what object it collides with
void checkCollisions() {
  for (Obstacle obstacle : obstacles) {
    if (obstacle.collidesWithPlayer()) {
      if (obstacle.img == fish) {
        score -= 50;
        fishCollision = true; // Set the fishCollision flag to true when colliding with a fish
      } else if (obstacle.img == oxygen) {
        fuel += 5;
        obstacle.respawn(); // respawns the oxygen obstacle
      } else {
        score += 20;
      }
      obstacle.respawn(); // respawns the collided obstacle
    }
  }
}

// Displays the score and fuel on the screen
void updateScore() {
  textSize(24);
  fill(255);
  textAlign(RIGHT, TOP);
  text("Plastic Collected: " + score, width - 20, 20);

  text("Oxygen: " + fuel, width - 20, 60);
}

// Displays game over message

void displayGameOver() {
  // Calculate the summary message based on the no. of collected plastics and fish collisions
  String summary;
  if (score <= 0) {
    summary = "You collected no plastics, hard luck!";
  } else if (score > 0 && fuel <= 0) {
    summary = "You collected " + score + " plastics, but you ran out of oxygen!";
  } else if (score >= 50) {
    summary = "You collected " + score + " plastics, well done!";
  } else if (fishCollision) {
    summary = "You collected " + score + " plastics, but fish collisions reduced your score!";
  } else {
    summary = "You collected " + score + " plastics, good job.";
  }

  background(0);
  textSize(32);
  fill(255);
  textAlign(CENTER, CENTER);
  text("Game Over" + "\n" + summary, width / 2, height / 2 - 50);

  // Restart button
  displayRestartButton();
  noLoop(); // Ends the game loop
}

void displayRestartButton() {
  // Displays a restart button on the screen once the game ends
  fill(0, 255, 0);
  rect(width / 2 - 50, height / 2 + 20, 100, 40);

  fill(255);
  textSize(18);
  textAlign(CENTER, CENTER);
  text("Restart", width / 2, height / 2 + 40);
}



void mousePressed() {
  // If the game is over and the restart button gets clicked by the player, the game restarts
  if (gameover && mouseX > width / 2 - 50 && mouseX < width / 2 + 50 &&
    mouseY > height / 2 + 20 && mouseY < height / 2 + 60) {
    restartGame();
  }
}

// Resets the game's state
void restartGame() {
  gameover = false;
  fuel = 25; // reset fuel to the initial fuel value
  score = 0; // reset the score to 0

  // resets the player's pos to the center of the screen (width/2 and height/2 = center)
  player_x = width / 2;
  player_y = height / 2;

  // Clears the existing obstacles and respawns with the obstacles.add
  obstacles.clear();
  obstacles.add(new Obstacle(fish, 3));
  obstacles.add(new Obstacle(bottle1, 2));
  obstacles.add(new Obstacle(bag, 2.5));
  obstacles.add(new Obstacle(foodWrapper, 2));
  obstacles.add(new Obstacle(oxygen, 2));
  loop(); // restarts the game loop
}




// Display warning message for fish collision
void displayFishWarning() {
  fill(255);
  textSize(15);
  textAlign(CENTER, TOP);
  text("Warning, do not collect fish, plastics only!\nWhen overfishing occurs in the ocean,\nit creates an imbalance that can erode the food web and lead to a loss of other important marine life, \nincluding vulnerable species like sea turtles and corals. - World Wildlife", width / 2, 10);
  //Source: https://www.worldwildlife.org/threats/overfishing#:~:text=It%20can%20change%20the%20size,like%20sea%20turtles%20and%20corals.
}





// Sprite moving with arrow-keys coded with a mix of ChatGPT + Lab3, and I coded it to go UP and DOWN
void keyPressed() {
  // Check if the game has started or if we're on the intro screen
  if (!gameStarted || introScreen) {
    // Start or restart the game
    introScreen = false;
    restartGame();
    gameStarted = true;
  } else {
    // Handle key presses during the game
    if (keyCode == RIGHT) {
      rightKeyPressed = true;
    } else if (keyCode == LEFT) {
      leftKeyPressed = true;
    } else if (keyCode == UP) {
      upKeyPressed = true;
    } else if (keyCode == DOWN) {
      downKeyPressed = true;
    }
  }
}


void keyReleased() {
  if (keyCode == RIGHT) {
    rightKeyPressed = false;
  } else if (keyCode == LEFT) {
    leftKeyPressed = false;
  } else if (keyCode == UP) {
    upKeyPressed = false;
  } else if (keyCode == DOWN) {
    downKeyPressed = false;
  }
}
