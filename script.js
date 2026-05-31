const fruit = document.getElementById("fruit");
const basket = document.getElementById("basket");
const scoreText = document.getElementById("score");
const lifeText = document.getElementById("life");

const startBtn = document.getElementById("startBtn");
const pauseBtn = document.getElementById("pauseBtn");
const restartBtn = document.getElementById("restartBtn");

let fruits = ["🍎", "🍌", "🍇", "🍊", "🍓", "🍉", "🍍", "🥭", "🍒", "🥝"];

let fruitX = 300;
let fruitY = 0;
let basketX = 270;

let score = 0;
let life = 3;
let speed = 4;
let basketSpeed = 65;

let gameInterval;
let isPlaying = false;
let isPaused = false;

document.addEventListener("keydown", function(e) {
  if (e.key === "ArrowLeft") {
    basketX -= basketSpeed;
  }

  if (e.key === "ArrowRight") {
    basketX += basketSpeed;
  }

  if (basketX < 0) {
    basketX = 0;
  }

  if (basketX > 570) {
    basketX = 570;
  }

  basket.style.left = basketX + "px";
});

function randomFruit() {
  fruit.textContent = fruits[Math.floor(Math.random() * fruits.length)];
  fruitX = Math.floor(Math.random() * 590);
  fruitY = 0;
  fruit.style.left = fruitX + "px";
  fruit.style.top = fruitY + "px";
}

function moveFruit() {
  if (!isPlaying || isPaused) return;

  fruitY += speed;
  fruit.style.top = fruitY + "px";

  if (fruitY >= 410) {
    if (fruitX + 45 >= basketX && fruitX <= basketX + 90) {
      score++;
      scoreText.textContent = score;
      speed += 0.25;
      randomFruit();
    } else {
      life--;
      lifeText.textContent = life;
      randomFruit();

      if (life <= 0) {
        clearInterval(gameInterval);
        isPlaying = false;
        alert("Game Over! Score kamu: " + score);
      }
    }
  }
}

startBtn.addEventListener("click", function() {
  if (!isPlaying) {
    isPlaying = true;
    isPaused = false;
    randomFruit();
    gameInterval = setInterval(moveFruit, 20);
  }
});

pauseBtn.addEventListener("click", function() {
  if (isPlaying) {
    isPaused = !isPaused;
    pauseBtn.textContent = isPaused ? "▶ RESUME" : "⏸ PAUSE";
  }
});

restartBtn.addEventListener("click", function() {
  clearInterval(gameInterval);

  score = 0;
  life = 3;
  speed = 4;
  basketSpeed = 65;
  fruitY = 0;
  basketX = 270;

  scoreText.textContent = score;
  lifeText.textContent = life;
  basket.style.left = basketX + "px";

  isPlaying = true;
  isPaused = false;
  pauseBtn.textContent = "⏸ PAUSE";

  randomFruit();
  gameInterval = setInterval(moveFruit, 20);
});
