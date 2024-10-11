import java.util.ArrayList;
import java.util.Stack;
import java.util.Collections;
import processing.sound.*;

PFont font;  // Fuente personalizada para mejorar el estilo del texto
PImage wallTexture, backgroundImage, menuBackground, pauseButtonImage,playerImage, goalImage;  // Imagen para la textura de las paredes

SoundFile moveSound, completeSound, loseLifeSound, hitWallSound;

int cols, rows;  // Columnas y filas
int w;           // Tamaño de cada celda (cuadrícula)
MazeCell[] grid;     // Array para todas las celdas
MazeCell current;    // Celda actual
Stack<MazeCell> stack = new Stack<MazeCell>();  // Pila para el recorrido DFS (para la dificultad fácil)
boolean huntMode = false;  // Para alternar entre "caza" y "matanza" en Hunt and Kill
int playerX = 0, playerY = 0;  // Posición del jugador (en celdas)
int goalX, goalY;  // Posición de la meta
int score = 1000;  // Puntuación inicial del nivel
int totalScore = 0;  // Puntuación acumulada
int startTime;  // Tiempo de inicio
boolean gameWon = false;  // Estado del juego
boolean hasMoved = false;  // Controla si el jugador se ha movido
int level = 1;  // Nivel inicial
int vidas = 3;  // Número inicial de vidas
boolean gameStarted = false;  // Control para saber si el juego ha comenzado
boolean isPaused = false;  // Estado de pausa
int dificultad = -1;  // Dificultad del juego: 0 = fácil (DFS), 1 = normal (Kruskal), 2 = difícil (Hunt and Kill)

PImage heartFilled, heartEmpty; // Imágenes para los corazones llenos y vacíos
ArrayList<Wall> walls;  // Lista de paredes entre celdas en Kruskal

int boardHeight = 50;  // Altura del tablero de puntuación (separado del laberinto)

void settings() {
  w = 40;  // Tamaño de cada celda (ajusta según sea necesario)
  cols = 10;  // Número de columnas del laberinto
  rows = 10;  // Número de filas del laberinto

  // Ajusta el tamaño total de la ventana, con un espacio para el tablero (boardHeight)
  size(cols * w, rows * w + boardHeight);  
}

void setup() {
  // Cargar la fuente predeterminada
  font = createFont("Arial", 32);  // Puedes cambiar "Arial" por el nombre de tu fuente o usar createFont con un archivo en 'data'
  textFont(font);  // Asignar la fuente cargada

  // Cargar los sonidos para las diferentes acciones
  moveSound = new SoundFile(this, "movement.mp3");
  completeSound = new SoundFile(this, "complet.mp3");
  loseLifeSound = new SoundFile(this, "perdervida.mp3");
  hitWallSound = new SoundFile(this, "chocarpared.mp3");  // Sonido de choque contra la pared
  
  // Cargar la imagen del botón de pausa
  pauseButtonImage = loadImage("pausa2.png");
  
  // Cargar imagen de textura
  wallTexture = loadImage("ladrillos.jpg");  // Asegúrate de tener esta imagen en la carpeta data
  backgroundImage = loadImage("cesped.jpg"); 
   // Imagen personalizada para el fondo del menú
  menuBackground = loadImage("fondomenu.jpeg");

  // Cargar las imágenes del jugador y la meta
  playerImage = loadImage("player.png");  // Asegúrate de que el archivo está en la carpeta 'data'
  goalImage = loadImage("meta.png");  // Asegúrate de que el archivo está en la carpeta 'data'

  heartFilled = loadImage("corzon.png");
  heartEmpty = loadImage("corazonvacio.png");
  textSize(18);

  iniciarNivel();
}

void draw() {
  if (!gameStarted) {
    mostrarPantallaDificultad();  // Pantalla de selección de dificultad
  } else if (isPaused) {
    mostrarMenuPausa();  // Mostrar el menú de pausa si está en pausa
  } else if (vidas == 0) {
    gameOver();  // Mostrar la pantalla de "Game Over" si no hay vidas
  } else {
    jugar();  // Aquí se dibuja el tablero y el laberinto
    mostrarBotonPausa();  // Mostrar el botón de pausa durante el juego
  }
}


// Función para mostrar el botón de pausa
void mostrarBotonPausa() {
  image(pauseButtonImage, width - 50, 10, 40, 40);  // Dibujar el botón en la esquina superior derecha
}

void mostrarPantallaDificultad() {
  // Dibujar el fondo del menú
  image(menuBackground, 0, 0, width, height);

  // Establecer la fuente personalizada y el color del texto
  textFont(font);  // Asegurarse de que la fuente se ha cargado
  fill(255);  // Texto en blanco
  textAlign(CENTER, CENTER);

  // Título del menú
  textSize(32);  // Tamaño del texto grande para el título
  text("Selecciona la Dificultad", width / 2, height / 4);

  // Opciones de dificultad
  textSize(32);  // Tamaño más pequeño para las opciones

  // Dibujar las opciones como botones visuales
  fill(255, 255, 255);  // Texto blanco
  if (mouseOverButton(width / 2 - 100, height / 2 - 40, 200, 50)) {
    fill(0, 255, 0);  // Resaltar con color verde si el mouse está sobre la opción
  }
  rect(width / 2 - 100, height / 2 - 40, 200, 50, 10);  // Botón con bordes redondeados
  fill(0);  // Texto negro dentro del botón
  text("Fácil", width / 2, height / 2 - 15);

  fill(255, 255, 255);
  if (mouseOverButton(width / 2 - 100, height / 2 + 40, 200, 50)) {
    fill(0, 255, 0);  // Resaltar
  }
  rect(width / 2 - 100, height / 2 + 40, 200, 50, 10);  // Botón normal
  fill(0);
  text("Normal", width / 2, height / 2 + 65);

  fill(255, 255, 255);
  if (mouseOverButton(width / 2 - 100, height / 2 + 120, 200, 50)) {
    fill(0, 255, 0);  // Resaltar
  }
  rect(width / 2 - 100, height / 2 + 120, 200, 50, 10);  // Botón para dificultad difícil
  fill(0);
  text("Difícil", width / 2, height / 2 + 145);
}

// Función para verificar si el mouse está sobre un botón
boolean mouseOverButton(int x, int y, int width, int height) {
  return (mouseX > x && mouseX < x + width && mouseY > y && mouseY < y + height);
}

// El resto de tu código, como mousePressed, iniciarNivel, etc.

// Menú de pausa
void mostrarMenuPausa() {
  // Dibujar el mismo fondo que el del menú de selección de dificultad
  image(menuBackground, 0, 0, width, height);  // Usar la misma imagen de fondo
  
  fill(255);
  textAlign(CENTER, CENTER);
  textSize(32);
  text("Juego Pausado", width / 2, height / 3);

  // Dibujar los botones del menú de pausa
  fill(255, 255, 255);
  if (mouseOverButton(width / 2 - 100, height / 2 - 40, 200, 50)) {
    fill(0, 255, 0);  // Resaltar el botón "Reanudar"
  }
  rect(width / 2 - 100, height / 2 - 40, 200, 50, 10);
  fill(0);
  text("Reanudar", width / 2, height / 2 - 15);

  fill(255, 255, 255);
  if (mouseOverButton(width / 2 - 100, height / 2 + 40, 200, 50)) {
    fill(0, 255, 0);  // Resaltar el botón "Volver al Menú"
  }
  rect(width / 2 - 100, height / 2 + 40, 200, 50, 10);
  fill(0);
  text("Volver al Menú", width / 2, height / 2 + 65);
}

// Detección del clic en el menú de pausa
void mousePressed() {
  if (isPaused) {
    if (mouseOverButton(width / 2 - 100, height / 2 - 40, 200, 50)) {
      isPaused = false;  // Reanudar el juego
    } else if (mouseOverButton(width / 2 - 100, height / 2 + 40, 200, 50)) {
      gameStarted = false;  // Volver al menú de selección de dificultad
    }
  } else if (mouseOverButton(width - 50, 10, 40, 40)) {
    isPaused = true;  // Pausar el juego
  } else if (!gameStarted) {
    // Lógica para seleccionar la dificultad en el menú principal
    if (mouseOverButton(width / 2 - 100, height / 2 - 40, 200, 50)) {
      dificultad = 0;  // Fácil
      gameStarted = true;
      iniciarNivel();
    } else if (mouseOverButton(width / 2 - 100, height / 2 + 40, 200, 50)) {
      dificultad = 1;  // Normal (Kruskal)
      gameStarted = true;
      iniciarNivel();
    } else if (mouseOverButton(width / 2 - 100, height / 2 + 120, 200, 50)) {
      dificultad = 2;  // Difícil (Hunt and Kill)
      gameStarted = true;
      iniciarNivel();
    }
  }
}
// Función para iniciar el juego basado en la dificultad seleccionada
void iniciarNivel() {
  startTime = millis();  // Iniciar el cronómetro
  switch (dificultad) {
    case 0:  // Fácil (DFS)
      w = 40;
      iniciarDFS();
      break;
    case 1:  // Normal (Kruskal)
      w = 30;
      iniciarKruskal();
      break;
    case 2:  // Difícil (Hunt and Kill)
      w = 20;
      iniciarHuntAndKill();
      break;
  }

  // Ajustar el tamaño de la ventana dinámicamente según el nuevo tamaño del laberinto
  surface.setSize(cols * w, rows * w + boardHeight);
}


int tiempoLimite = 60;  // Tiempo límite en segundos para completar el nivel
// Función jugar modificada para verificar si el jugador llega a la meta
void jugar() {
  image(backgroundImage, 0, 0, width, height);

  // Mostrar el tablero de puntuación antes del laberinto
  mostrarTablero();

  // Dibujar todas las celdas del laberinto
  for (MazeCell c : grid) {
    c.show();
  }

  // Dibujar al jugador y la meta con imágenes en lugar de rectángulos
  image(playerImage, playerX * w, playerY * w + boardHeight, w, w);  // Imagen del jugador
  image(goalImage, goalX * w, goalY * w + boardHeight, w, w);  // Imagen de la meta

  // Ejecución del algoritmo según la dificultad
  switch (dificultad) {
    case 0:  // Fácil (DFS)
      ejecutarDFS();
      break;
    case 1:  // Normal (Kruskal)
      ejecutarKruskal();
      break;
    case 2:  // Difícil (Hunt and Kill)
      ejecutarHuntAndKill();
      break;
  }

  // Verificar si el jugador ha llegado a la meta
  if (playerX == goalX && playerY == goalY && !gameWon) {
    gameWon = true;
    completeSound.play();  // Sonido al completar el nivel
    completarNivel();      // Llamar a la función para generar un nuevo nivel
  }

  // Comprobar si el tiempo ha excedido el límite
  int tiempoTranscurrido = (millis() - startTime) / 1000;  // Tiempo en segundos
  if (tiempoTranscurrido > tiempoLimite) {
    perderVida();  // Perder una vida si el tiempo se agota
  }
}
void perderVida() {
  if (vidas > 0) {
    vidas--;
    loseLifeSound.play();  // Sonido al perder una vida
    if (vidas == 0) {
      gameOver();  // Llamar a la función de "Game Over"
    } else {
      // Reiniciar el nivel si aún tiene vidas
      iniciarNivel();
    }
  }
}
void gameOver() {
  fill(0, 0, 0, 150);  // Fondo semi-transparente
  rect(0, 0, width, height);  // Cubrir toda la pantalla

  fill(255);
  textAlign(CENTER, CENTER);
  textSize(48);
  text("Game Over", width / 2, height / 2 - 50);
  textSize(24);
  text("Presiona R para reiniciar", width / 2, height / 2 + 50);
}

// Mostrar las paredes usando la textura
void mostrarParedes(MazeCell cell) {
  int x = cell.i * w;
  int y = cell.j * w + boardHeight;

  // Dibujar las paredes usando la textura en lugar de líneas
  if (cell.walls[0]) image(wallTexture, x, y, w, 4);  // Pared superior
  if (cell.walls[1]) image(wallTexture, x + w - 4, y, 4, w);  // Pared derecha
  if (cell.walls[2]) image(wallTexture, x, y + w - 4, w, 4);  // Pared inferior
  if (cell.walls[3]) image(wallTexture, x, y, 4, w);  // Pared izquierda
}

// Clase MazeCell para representar cada celda del laberinto
class MazeCell {
  int i, j;
  boolean[] walls = {true, true, true, true};  // Paredes de la celda (arriba, derecha, abajo, izquierda)
  boolean visited = false;  // Para saber si la celda ha sido visitada
  int set;  // Para el algoritmo de Kruskal, la celda pertenece a un conjunto

  MazeCell(int i, int j) {
    this.i = i;
    this.j = j;
    this.set = i + j * cols;  // Inicializar el conjunto de Kruskal
  }

  void show() {
    mostrarParedes(this);  // Llamar a la función para dibujar las paredes
  }
}

// Mostrar el tablero de puntuación en formato 2x2 (dos elementos por fila)
void mostrarTablero() {
  fill(0, 0, 0, 150);  // Fondo semi-transparente
  noStroke();
  rect(0, 0, width, boardHeight);  // Dibujar el rectángulo en la parte superior

  fill(255);
  textAlign(LEFT, CENTER);
  textSize(12);  // Tamaño de texto ajustado
  
  // Definir posiciones para los textos
  int paddingX = 150;  // Espaciado horizontal entre columnas
  int posY1 = 20;  // Primera fila (Texto arriba)
  int posY2 = 40;  // Segunda fila (Texto abajo)

  // Calcular el tiempo restante
  int tiempoTranscurrido = (millis() - startTime) / 1000;  // Tiempo en segundos
  int tiempoRestante = max(tiempoLimite - tiempoTranscurrido, 0);  // Asegurar que no sea negativo

  // Primera fila: Tiempo restante y Puntuación
  text("Tiempo restante: " + tiempoRestante + " s", 10, posY1);  // Mostrar el tiempo restante
  text("Puntuación: " + score, 10 + paddingX, posY1);

  // Segunda fila: Nivel y Vidas
  text("Nivel: " + level, 10, posY2);
  text("Vidas: ", 10 + paddingX, posY2);

  // Dibujar las vidas
  for (int i = 0; i < 3; i++) {
    if (i < vidas) {
      image(heartFilled, 110 + paddingX + i * 25, posY2 - 10, 20, 20);  // Corazones llenos
    } else {
      image(heartEmpty, 110 + paddingX + i * 25, posY2 - 10, 20, 20);  // Corazones vacíos
    }
  }
}


// Funciones DFS, Kruskal, y Hunt and Kill (las funciones que ya tienes en tu código)
// Aquí se mantienen sin cambios

// Función para inicializar el algoritmo DFS (para la dificultad fácil)
void iniciarDFS() {
  cols = floor(width / w);
  rows = floor((height - 50) / w);  // Restamos el tamaño del tablero al calcular filas
  grid = new MazeCell[cols * rows];

  for (int j = 0; j < rows; j++) {
    for (int i = 0; i < cols; i++) {
      grid[i + j * cols] = new MazeCell(i, j);
    }
  }

  current = grid[0];
  goalX = cols - 1;
  goalY = rows - 1;
  playerX = 0;
  playerY = 0;
  hasMoved = false;
  gameWon = false;
  stack.clear();  // Limpiar la pila para DFS
}

// Función para ejecutar DFS
void ejecutarDFS() {
  if (!gameWon) {
    current.visited = true;
    MazeCell next = checkNeighborsDFS(current);  // DFS utiliza su propia función de vecinos

    if (next != null) {
      next.visited = true;
      stack.push(current);
      removeWalls(current, next);
      current = next;
    } else if (!stack.isEmpty()) {
      current = stack.pop();
    }
  }
}

// Función para obtener los vecinos no visitados en DFS
MazeCell checkNeighborsDFS(MazeCell cell) {
  ArrayList<MazeCell> neighbors = new ArrayList<MazeCell>();

  int top = index(cell.i, cell.j - 1);
  int right = index(cell.i + 1, cell.j);
  int bottom = index(cell.i, cell.j + 1);
  int left = index(cell.i - 1, cell.j);

  if (top != -1 && !grid[top].visited) neighbors.add(grid[top]);
  if (right != -1 && !grid[right].visited) neighbors.add(grid[right]);
  if (bottom != -1 && !grid[bottom].visited) neighbors.add(grid[bottom]);
  if (left != -1 && !grid[left].visited) neighbors.add(grid[left]);

  if (neighbors.size() > 0) {
    int r = floor(random(neighbors.size()));
    return neighbors.get(r);
  } else {
    return null;
  }
}
// Función para inicializar el algoritmo de Kruskal (para dificultad normal)
void iniciarKruskal() {
  cols = floor(width / w);
  rows = floor((height - 50) / w);  // Restamos el tamaño del tablero
  grid = new MazeCell[cols * rows];

  // Inicializar las celdas
  for (int j = 0; j < rows; j++) {
    for (int i = 0; i < cols; i++) {
      grid[i + j * cols] = new MazeCell(i, j);
      grid[i + j * cols].set = i + j * cols; // Cada celda empieza en su propio conjunto
    }
  }

  current = grid[0];
  goalX = cols - 1;
  goalY = rows - 1;
  playerX = 0;
  playerY = 0;
  hasMoved = false;
  gameWon = false;

  // Crear una lista de todas las paredes
  walls = new ArrayList<Wall>();
  for (int j = 0; j < rows; j++) {
    for (int i = 0; i < cols; i++) {
      MazeCell currentCell = grid[i + j * cols];

      // Añadir las paredes entre las celdas adyacentes
      if (i < cols - 1) {
        walls.add(new Wall(currentCell, grid[i + 1 + j * cols])); // Pared derecha
      }
      if (j < rows - 1) {
        walls.add(new Wall(currentCell, grid[i + (j + 1) * cols])); // Pared inferior
      }
    }
  }

  // Mezclar las paredes para generar aleatoriedad
  Collections.shuffle(walls);
}

// Función para ejecutar el algoritmo de Kruskal
void ejecutarKruskal() {
  if (!walls.isEmpty()) {
    Wall wall = walls.remove(walls.size() - 1);  // Tomar una pared aleatoria

    // Verificar que las celdas no estén en el mismo conjunto antes de eliminar la pared
    if (find(wall.a) != find(wall.b)) {
      removeWalls(wall.a, wall.b); // Eliminar la pared entre las celdas
      union(wall.a, wall.b);       // Unir los conjuntos
    }
  } else {
    // Si no hay más paredes que procesar, el algoritmo ha terminado
    gameWon = true;
  }
}

// Implementación de la función find() para Kruskal
int find(MazeCell cell) {
  if (cell.set != cell.i + cell.j * cols) { // Si no es su propio set
    cell.set = find(grid[cell.set]);  // Búsqueda de raíz con compresión de caminos
  }
  return cell.set;
}

// Función para unir dos conjuntos en Kruskal
void union(MazeCell a, MazeCell b) {
  int rootA = find(a);
  int rootB = find(b);
  if (rootA != rootB) {
    grid[rootB].set = rootA;  // Unir los conjuntos
  }
}



// Función para inicializar el algoritmo de Hunt and Kill (para dificultad difícil)
void iniciarHuntAndKill() {
  cols = floor(width / w);
  rows = floor((height - 50) / w);  // Restamos el tamaño del tablero
  grid = new MazeCell[cols * rows];

  // Inicializar las celdas
  for (int j = 0; j < rows; j++) {
    for (int i = 0; i < cols; i++) {
      grid[i + j * cols] = new MazeCell(i, j);
    }
  }

  current = grid[0];
  current.visited = true;
  huntMode = false; // Comenzamos con el modo "matar"

  goalX = cols - 1;
  goalY = rows - 1;
  playerX = 0;
  playerY = 0;
  gameWon = false;
}

// Función para ejecutar el algoritmo de Hunt and Kill
void ejecutarHuntAndKill() {
  if (!gameWon) {
    if (!huntMode) {  // Fase de "matar" (caminar aleatoriamente)
      MazeCell next = checkNeighborsHuntKill(current);

      if (next != null) {
        next.visited = true;
        removeWalls(current, next);
        current = next;
      } else {
        huntMode = true;  // Cambiar a fase de "caza"
      }
    } else {  // Fase de "caza" (buscar una celda no visitada)
      boolean found = false;
      for (int j = 0; j < rows && !found; j++) {
        for (int i = 0; i < cols && !found; i++) {
          MazeCell cell = grid[i + j * cols];
          if (!cell.visited && hasVisitedNeighbor(cell)) {
            current = cell;
            current.visited = true;
            huntMode = false;  // Volver a fase de "matar"
            MazeCell neighbor = getVisitedNeighbor(current);  // Conectar con un vecino visitado
            if (neighbor != null) {
              removeWalls(current, neighbor);
            }
            found = true;
          }
        }
      }
      if (!found) {
        // Finalizamos la generación del laberinto pero NO cambiamos de nivel aquí
        // El cambio de nivel se hará solo cuando el jugador llegue a la meta
      }
    }
  }
}


// Función para buscar vecinos no visitados en Hunt and Kill
MazeCell checkNeighborsHuntKill(MazeCell cell) {
  ArrayList<MazeCell> neighbors = new ArrayList<MazeCell>();

  int top = index(cell.i, cell.j - 1);    // Vecino superior
  int right = index(cell.i + 1, cell.j);  // Vecino derecho
  int bottom = index(cell.i, cell.j + 1); // Vecino inferior
  int left = index(cell.i - 1, cell.j);   // Vecino izquierdo

  if (top != -1 && !grid[top].visited) neighbors.add(grid[top]);
  if (right != -1 && !grid[right].visited) neighbors.add(grid[right]);
  if (bottom != -1 && !grid[bottom].visited) neighbors.add(grid[bottom]);
  if (left != -1 && !grid[left].visited) neighbors.add(grid[left]);

  if (neighbors.size() > 0) {
    int r = floor(random(neighbors.size()));  // Elegir un vecino aleatorio
    return neighbors.get(r);
  } else {
    return null;
  }
}

// Clase Wall para representar las paredes entre celdas en Kruskal
class Wall {
  MazeCell a, b;  // Las dos celdas que están separadas por esta pared

  Wall(MazeCell a, MazeCell b) {
    this.a = a;
    this.b = b;
  }
}

// Función para obtener el índice de una celda en el array
int index(int i, int j) {
  if (i < 0 || j < 0 || i >= cols || j >= rows) return -1;
  return i + j * cols;
}
void keyPressed() {
  if (!gameStarted) {
    if (key == '1') {
      dificultad = 0;  // Fácil (DFS)
      gameStarted = true;
      iniciarNivel();
    } else if (key == '2') {
      dificultad = 1;  // Normal (Kruskal)
      gameStarted = true;
      iniciarNivel();
    } else if (key == '3') {
      dificultad = 2;  // Difícil (Hunt and Kill)
      gameStarted = true;
      iniciarNivel();
    }
  } else if (key == 'p' || key == 'P') {
    isPaused = !isPaused;  // Alternar pausa
  } else if (!isPaused && vidas > 0) {
    moverJugador();  // Mover jugador si no está en pausa y tiene vidas
  } else if (vidas == 0 && (key == 'r' || key == 'R')) {
    reiniciarJuego();  // Reiniciar el juego si se presiona 'R'
  }
}

void reiniciarJuego() {
  totalScore = 0;
  vidas = 3;
  level = 1;
  gameStarted = false;
  iniciarNivel();
}



void moverJugador() {
  MazeCell currentCell = grid[playerX + playerY * cols];
  
  if (key == 'w' || key == 'W' || keyCode == UP) {
    if (!currentCell.walls[0]) {
      playerY--;
      moveSound.play();  // Sonido de movimiento
    } else {
      hitWallSound.play();  // Sonido de choque contra la pared
    }
  } else if (key == 's' || key == 'S' || keyCode == DOWN) {
    if (!currentCell.walls[2]) {
      playerY++;
      moveSound.play();
    } else {
      hitWallSound.play();
    }
  } else if (key == 'a' || key == 'A' || keyCode == LEFT) {
    if (!currentCell.walls[3]) {
      playerX--;
      moveSound.play();
    } else {
      hitWallSound.play();
    }
  } else if (key == 'd' || key == 'D' || keyCode == RIGHT) {
    if (!currentCell.walls[1]) {
      playerX++;
      moveSound.play();
    } else {
      hitWallSound.play();
    }
  }

  if (!hasMoved) {
    hasMoved = true;
    startTime = millis();
  }
}


// Función para completar el nivel y pasar al siguiente
void completarNivel() {
  totalScore += score;  // Sumar la puntuación actual al total
  level++;  // Avanzar al siguiente nivel
  println("Nivel completado. Iniciando nuevo nivel: " + level);

  gameWon = false;  // Reiniciar el estado del juego para el próximo nivel
  iniciarNivel();  // Llamar a la función que reinicia el nivel
}

// Función para buscar vecinos visitados (usada en Hunt and Kill)
boolean hasVisitedNeighbor(MazeCell cell) {
  return getVisitedNeighbor(cell) != null;
}

// Función para obtener vecinos visitados (usada en Hunt and Kill)
MazeCell getVisitedNeighbor(MazeCell cell) {
  ArrayList<MazeCell> neighbors = new ArrayList<MazeCell>();

  int top = index(cell.i, cell.j - 1);    // Vecino superior
  int right = index(cell.i + 1, cell.j);  // Vecino derecho
  int bottom = index(cell.i, cell.j + 1); // Vecino inferior
  int left = index(cell.i - 1, cell.j);   // Vecino izquierdo

  if (top != -1 && grid[top].visited) neighbors.add(grid[top]);
  if (right != -1 && grid[right].visited) neighbors.add(grid[right]);
  if (bottom != -1 && grid[bottom].visited) neighbors.add(grid[bottom]);
  if (left != -1 && grid[left].visited) neighbors.add(grid[left]);

  if (neighbors.size() > 0) {
    int r = floor(random(neighbors.size()));  // Elegir un vecino aleatorio
    return neighbors.get(r);
  } else {
    return null;
  }
}

// Función para eliminar las paredes entre dos celdas
void removeWalls(MazeCell a, MazeCell b) {
  int x = a.i - b.i;
  if (x == 1) {
    a.walls[3] = false; // Eliminar pared izquierda de a
    b.walls[1] = false; // Eliminar pared derecha de b
  } else if (x == -1) {
    a.walls[1] = false; // Eliminar pared derecha de a
    b.walls[3] = false; // Eliminar pared izquierda de b
  }

  int y = a.j - b.j;
  if (y == 1) {
    a.walls[0] = false; // Eliminar pared superior de a
    b.walls[2] = false; // Eliminar pared inferior de b
  } else if (y == -1) {
    a.walls[2] = false; // Eliminar pared inferior de a
    b.walls[0] = false; // Eliminar pared superior de b
  }
}
