require 'ruby2d'

set title: "Mario Game", width: 800, height: 600

#dodanie tła
background = Image.new('assets/images/mario-background.png', x: 0, y: 0)

#dodanie postaci
mario = Sprite.new('assets/images/mario.png', x: 50, y: 455, width: 50, height: 50, clip_width: 16, time: 80,
  animations: {
    idle: 0..0,
    walk: 1..3,
    jump: 5..5
    #die: 6..6
})

def create_enemies(enemy_data, sprite_path)
  enemy_data.map do |data|
    x, y, range = data
    {
      sprite: Sprite.new(sprite_path, x: x, y: y, width: 50, height: 50, clip_width: 16, time: 100,
      animations: { 
        move_left: 0..0, 
        move_right: 1..1, 
        die: 2..2 
      }),
      range: range, # Zakres ruchu [lewa_granica, prawa_granica]
      direction: :right, # Kierunek początkowy
      speed: 2,
      alive: true,
      initial_x: x, # Początkowa pozycja w grze (nigdy nie zmienia się względem kamery)
      initial_y: y
    }
  end   
end  

enemy_data = [ #x, y, zasieg x, zasieg  y
  [350, 455, [225, 600]], # Przeciwnik na podłodze
  [450, 150, [400, 500]], # Przeciwnik na platformie
  [1550, 455, [1500, 1600]], # Przeciwnik w dalszej części gry
]

enemies = create_enemies(enemy_data, 'assets/images/monster.png')


def create_castle(x, y, width, height, image_path)
  Image.new(image_path, x: x, y: y, width: width, height: height)
end

castle = create_castle(3750, 324, 144, 176, 'assets/images/castle.png')

# Funkcja do tworzenia platform z predefiniowanych pozycji
def create_platforms(platform_data, image_path)
  platform_data.map do |data|
    x, y, width, height = data
    Image.new(image_path, x: x, y: y, width: width, height: height)
  end
end

platform_data = [ # x, y, width, height
  [225, 325, 50, 50], # Pierwsza platforma
  [350, 325, 50, 50], # Druga platforma
  [390, 325, 50, 50], # Trzecia platforma
  [550, 325, 50, 50],
  [400, 200, 50, 50],
  [450, 200, 50, 50],
  [1500, 200, 50, 50],
  [1550, 200, 50, 50],
  [2550, 325, 50, 50],
  [2700, 200, 50, 50],
  [2750, 200, 50, 50],
  [2800, 200, 50, 50],
  [3000, 200, 50, 50],
  [3050, 200, 50, 50],
]

# Tworzenie platform
platforms = create_platforms(platform_data, 'assets/images/brick_block.png')

# tworzenie tub
def create_tubes(tube_data, tube_image, tube_lower_image, plant_image, tubes_with_plants)
  tubes = []
  tube_data.each_with_index do |data, index|
    x, y, height = data
    tube_upper = Image.new(tube_image, x: x, y: y, width: 76, height: 50)
    tube_lower = Image.new(tube_lower_image, x: x, y: y + 50, width: 76, height: height - 50)
    plant = nil
    # Dodaj roślinę tylko do wybranych tub
    if tubes_with_plants.include?(index)
      plant = Sprite.new(plant_image, x: x + 20, y: y - 40, width: 30, height: 40, clip_width: 16, time: 100,
        animations: {
          closed: 0..0,
          open: 0..1
        }
      )
      plant.play animation: :open, loop: true # Animacja rośliny w pętli
    end

    tubes << { upper: tube_upper, lower: tube_lower, plant: plant, y_top: y }
  end
  tubes
end

# Dane o tubach (x, y, wysokość)
tube_data = [
  [775, 400, 150],    # Pierwsza tuba
  [1050, 310, 240],   # Druga tuba
  [1600, 350, 200],   # Trzecia tuba
  [1800, 450, 100],   # Czwarta tuba
  [2000, 450, 100],   # Piąta tuba
  [2200, 450, 100],   # Szósta tuba
  [3200, 450, 100],   # Siódma tuba
  [3400, 450, 100]    # Ósma tuba
]
# W których tubach mają być roślinki
tubes_with_plants = [3, 4, 5, 7]

# Tworzenie tub
tubes = create_tubes(tube_data, 'assets/images/tube.png', 'assets/images/tube_lower.png', 'assets/images/plant.png', tubes_with_plants)

# Funkcja do tworzenia podłogi z segmentami i dziurami
def create_floor(start_x, y, segments, segment_width, gap_indexes, image_path)
  floor = []
  segments.times do |i|
    unless gap_indexes.include?(i) # Jeśli indeks jest w dziurach, pomiń
      floor << Image.new(image_path, x: start_x + i * segment_width, y: y, width: segment_width, height: 100)
    end
  end
  floor
end

# Tworzenie podłogi z dziurami
floor_segments = create_floor(0, 500, 100, 50, [ 23, 24, 25, 50, 51, 52, 53, 54, 55, 56, 57, 58], 'assets/images/grass.png') # Dziury w 4., 8. i 13. segmencie

def create_coins(coin_data, image_path)
  coin_data.map do |x, y|
    Image.new(image_path, x: x, y: y, width: 30, height: 30)
  end
end

coin_data = [
  [300, 335],
  [435, 130],
  [600, 130],
  [475, 335],
  [1535, 130],
  [1925, 300], # tuby 
  [2125, 300],
  [2735, 130], # wysoko blisko siebie
  [2785, 130],
  [3015, 275],
  [3065, 275],
  [3035, 130],
  [3325, 300]
]

coins = create_coins(coin_data, 'assets/images/coin.png')

$score = 0 # Zmienna do zliczania punktów
lives = 3 # Zmienna żyć

initial_position = [50, 455] # początkowe współrzędne Mario
initial_floor_positions = floor_segments.map(&:x)
initial_tube_positions = tube_data.map { |data| [data[0], data[0]] }
initial_platform_positions = platform_data.map { |data| data[0] }
initial_coins_position = coin_data.map { |x, y| [x, y] }
initial_enemy_positions = enemy_data.map { |data| [data[0], data[1]] }



def reset_game(mario, background, floor_segments, platforms, tubes, initial_position, initial_floor_positions, initial_tube_positions, 
  initial_platform_positions, castle, initial_coins_position, coins, score_text, initial_enemy_positions, enemies)
  # Reset pozycji Mario
  mario.x, mario.y = initial_position

  # Reset tła
  background.x = 0

  # Reset podłogi
  floor_segments.each_with_index do |segment, i|
    segment.x = initial_floor_positions[i] 
  end

  # Reset platform
  platforms.each_with_index do |platform, i|
    platform.x = initial_platform_positions[i]
  end

  # Reset tub
  tubes.each_with_index do |tube, i|
    tube[:upper].x, tube[:lower].x = initial_tube_positions[i]
    tube[:plant].x = initial_tube_positions[i][0] + 20 if tube[:plant]
  end

  # Reset potworków
  enemies.each_with_index do |enemy, i|
    if enemy[:alive] == false
      enemy[:sprite].play animation: :move_left, loop: true
      #enemy[:sprite].remove
      #enemy[:sprite] = Sprite.new('assets/images/monster.png', width: 50, height: 50, clip_width: 16, time: 100)
    end
    enemy[:sprite].x, enemy[:sprite].y = initial_enemy_positions[i] # Reset pozycji
    enemy[:direction] = :right  # Reset kierunku
    enemy[:alive] = true  # Potwór wciąż żywy
  end

  # Reset zamku
  castle.x = 3750

  # Reset coins 
  coins.each_with_index do |coin, i|
    coin.x, coin.y = initial_coins_position[i]
  end

  # Reset punktów
  $score = 0
  score_text.text = "Score: #{$score}"
end

# Zmienne ruchu
velocity_y = 0
gravity = 1
jump_strength = -20
is_jumping = false
speed = 5

#ruch tła
background_scroll_speed = 5

# Obsługa klawiatury
on :key_held do |event|
  case event.key
  when 'left'
    mario.play animation: :walk, loop: false, flip: :horizontal
    if mario.x > 0
      mario.x -= speed 
    end
  when 'right'
        mario.play animation: :walk, loop: false
        if mario.x < (Window.width - 250)
          mario.x += speed 
        else
          if (background.x - Window.width) > -background.width
          background.x -= speed
          floor_segments.each { |segment| segment.x -= background_scroll_speed }
          platforms.each { |platform| platform.x -= background_scroll_speed } # Dodane przesuwanie platform
          tubes.each do |tube|
            tube[:upper].x -= background_scroll_speed
            tube[:lower].x -= background_scroll_speed
            if tube[:plant] # Sprawdzenie, czy roślina istnieje
              tube[:plant].x -= background_scroll_speed
            end
          end
          enemies.each do |enemy|
            enemy[:sprite].x -= background_scroll_speed
          end
          castle.x -= background_scroll_speed
          coins.each do |coin|
            coin.x -= background_scroll_speed
          end

        end
    end
  when 'space'
    if !is_jumping
      velocity_y = jump_strength
      is_jumping = true
      mario.play animation: :jump, loop: false # Animacja skoku
    end
  end
end

lives_text = Text.new("Lives: #{lives}", x: 10, y: 10, size: 20, color: 'white')
score_text = Text.new("Score: #{$score}", x: 100, y: 10, size: 20, color: 'white')

game_lost = false
game_canvas_time = 0

update do

  if game_lost == true
    game_canvas_time -= 1
    sleep(1)
    if game_canvas_time <= 0
      Window.close
    end
    return
  end

  # Grawitacja: zmiana prędkości w pionie i aktualizacja pozycji
  velocity_y += gravity
  mario.y += velocity_y

  lives_text.text = "Lives: #{lives}" # Aktualizacja liczby żyć
  score_text.text = "Score: #{$score}" # Zbieranie punktow - tekst

  if mario.y > 600 # Mario wpada do dziury
    lives -= 1
    if lives > 0
      reset_game(mario, background, floor_segments, platforms, tubes, initial_position, initial_floor_positions, initial_tube_positions, 
      initial_platform_positions, castle, initial_coins_position, coins, score_text, initial_enemy_positions, enemies)
    else
      game_over_image = Image.new('assets/images/game_over.png', x: 0, y: 0, width: Window.width, height: Window.height)
      game_lost = true
    end
  end

  enemies.each do |enemy|
    next unless enemy[:alive] # Jeśli przeciwnik martwy, pomijamy
  
    # Ruch przeciwnika
    if enemy[:direction] == :right
      if enemy[:sprite].x - background.x + enemy[:sprite].width < enemy[:range][1]
        enemy[:sprite].x += enemy[:speed]
      else
        enemy[:direction] = :left
      end
    elsif enemy[:direction] == :left
      if  enemy[:sprite].x - background.x > enemy[:range][0]
        enemy[:sprite].x -= enemy[:speed]
      else
        enemy[:direction] = :right
      end
    end
  
  
    # Kolizje z Mario
    if mario.x < enemy[:sprite].x + enemy[:sprite].width &&
       mario.x + mario.width > enemy[:sprite].x &&
       mario.y < enemy[:sprite].y + enemy[:sprite].height &&
       mario.y + mario.height > enemy[:sprite].y
  
      if mario.y + mario.height - 10 < enemy[:sprite].y # Skok na przeciwnika
        enemy[:alive] = false
        enemy[:sprite].play animation: :die, loop: true
        $score += 200
        score_text.text = "Score: #{$score}"
      else # Kontakt boczny
        lives -= 1
        if lives > 0
          reset_game(mario, background, floor_segments, platforms, tubes, initial_position, initial_floor_positions,
                     initial_tube_positions, initial_platform_positions, castle, initial_coins_position, coins, score_text, initial_enemy_positions, enemies)
        else
          game_over_image = Image.new('assets/images/game_over.png', x: 0, y: 0, width: Window.width, height: Window.height)
          game_lost = true
        end
      end
    end
  end
  

  # kolizja z platformami
  platforms.each do |platform|
    if mario.y + mario.height >= platform.y &&
      mario.y + mario.height <= platform.y + 15 && # Tolerancja kolizji
      mario.x + mario.width > platform.x &&
      mario.x < platform.x + platform.width &&
      velocity_y >= 0 # Tylko jeśli Mario opada
     mario.y = platform.y - mario.height
     velocity_y = 0
     is_jumping = false
     break # Zatrzymujemy pętlę, aby uniknąć nadpisania pozycji
    end
    # Kolizja z dołem platformy
    if mario.y <= platform.y + platform.height &&
      mario.y >= platform.y + platform.height - 15 && # Tolerancja dla dołu platformy
      mario.x + mario.width > platform.x &&
      mario.x < platform.x + platform.width &&
      velocity_y < 0 # Tylko jeśli Mario skacze w górę
     mario.y = platform.y + platform.height
     velocity_y = 0 # Zatrzymujemy ruch w górę
     break
    end
    # Kolizja z lewej strony platformy
    if mario.x + mario.width >= platform.x &&
      mario.x + mario.width <= platform.x + 10 && # Tolerancja kolizji z lewej
      mario.y + mario.height > platform.y &&
      mario.y < platform.y + platform.height
    mario.x = platform.x - mario.width # Zatrzymanie Mario przed platformą
    end
    # Kolizja z prawej strony platformy
    if mario.x <= platform.x + platform.width &&
      mario.x >= platform.x + platform.width - 10 && # Tolerancja kolizji z prawej
      mario.y + mario.height > platform.y &&
      mario.y < platform.y + platform.height
    mario.x = platform.x + platform.width # Zatrzymanie Mario po drugiej stronie
    end
  end

   # Kolizja z tubami 
   tubes.each do |tube|
    # Góra tuby
    if mario.y + mario.height >= tube[:upper].y &&
       mario.y + mario.height <= tube[:upper].y + 15 &&
       mario.x + mario.width > tube[:upper].x &&
       mario.x < tube[:upper].x + tube[:upper].width &&
       velocity_y >= 0 # Opadający Mario
      mario.y = tube[:upper].y - mario.height
      velocity_y = 0
      is_jumping = false
      break
    end
    # Lewa strona tuby
    if mario.x + mario.width > tube[:lower].x &&
       mario.x < tube[:lower].x + 10 && # Tolerancja kolizji po lewej
       mario.y + mario.height > tube[:lower].y &&
       mario.y < tube[:lower].y + tube[:lower].height
      mario.x = tube[:lower].x - mario.width # Zatrzymanie Mario przed tubą
    end
    # Prawa strona tuby
    if mario.x < tube[:lower].x + tube[:lower].width &&
       mario.x + mario.width > tube[:lower].x + tube[:lower].width - 10 && # Tolerancja
       mario.y + mario.height > tube[:lower].y &&
       mario.y < tube[:lower].y + tube[:lower].height
      mario.x = tube[:lower].x + tube[:lower].width # Zatrzymanie Mario po drugiej stronie
    end
    # Kolizja z rośliną
    if tube[:plant] && mario.x < tube[:plant].x + tube[:plant].width &&
      mario.x + mario.width > tube[:plant].x &&
      mario.y < tube[:plant].y + tube[:plant].height &&
      mario.y + mario.height > tube[:plant].y
     puts "Mario traci życie przez kwiatka!"
     lives -= 1
     if lives > 0
       reset_game(mario, background, floor_segments, platforms, tubes, initial_position, initial_floor_positions, initial_tube_positions, 
       initial_platform_positions, castle, initial_coins_position, coins, score_text, initial_enemy_positions, enemies)
     else
       game_over_image = Image.new('assets/images/game_over.png', x: 0, y: 0, width: Window.width, height: Window.height)
       game_lost = true
       return
     end
   end
  end

  # Kolizja Mario z monetami
  coins.each do |coin|
    if mario.x < coin.x + coin.width &&
       mario.x + mario.width > coin.x &&
       mario.y < coin.y + coin.height &&
       mario.y + mario.height > coin.y
      coins.delete(coin)  # Usunięcie monety z listy
      coin.remove         # Usunięcie monety z ekranu
      $score += 100       # Dodanie punktów
      score_text.text = "Score: #{$score}"
    end
  end

  # Sprawdzanie kolizji z podłogą
  on_floor = false
  floor_segments.each do |segment|
    if mario.y + mario.height >= segment.y &&
       mario.y + mario.height <= segment.y + 30 && # Tolerancja kolizji
       mario.x + mario.width > segment.x &&
       mario.x < segment.x + segment.width 
       mario.y = segment.y - mario.height
       velocity_y = 0
       is_jumping = false
      #mario.play animation: :idle, loop: true
       on_floor = true
    end
  end

  if !on_floor
    if mario.y > 600
      velocity_y = -15
      #puts "Game Over! Mario fell into a hole!"
      #sleep(2)
      #Window.close
    end
  end

  # Sprawdzanie kolizji Mario z zamkiem
  if mario.x + mario.width > castle.x &&
    mario.x < castle.x + castle.width &&
    mario.y + mario.height > castle.y &&
    mario.y < castle.y + castle.height

   # Wyświetlenie obrazka "YOU WIN" i zakończenie gry
   you_win_image = Image.new('assets/images/you_win.png', x: 0, y: 0, width: Window.width, height: Window.height)
   game_lost = true # Wyświetlanie ekranu przez 3 sekundy
   #Window.close
 end

end

show


# require 'ruby2d'

# set title: "Mario Game", width: 800, height: 600

# #dodanie tła
# background = Image.new('assets/images/mario-background.png', x: 0, y: 0)

# #dodanie postaci
# mario = Sprite.new('assets/images/mario.png', x: 50, y: 455, width: 50, height: 50, clip_width: 16, time: 80,
#   animations: {
#     idle: 0..0,
#     walk: 1..3,
#     jump: 5..5
#     #die: 6..6
# })

# def create_enemies(enemy_data, sprite_path)
#   enemy_data.map do |data|
#     x, y, range = data
#     {
#       sprite: Sprite.new(sprite_path, x: x, y: y, width: 50, height: 50, clip_width: 16, time: 100,
#       animations: { 
#         move_left: 0..0, 
#         move_right: 1..1, 
#         die: 2..2 
#       }),
#       range: range, # Zakres ruchu [lewa_granica, prawa_granica]
#       direction: :right, # Kierunek początkowy
#       speed: 2,
#       alive: true,
#       initial_x: x, # Początkowa pozycja w grze (nigdy nie zmienia się względem kamery)
#       initial_y: y
#     }
#   end   
# end  

# enemy_data = [ #x, y, zasieg x, zasieg  y
#   [350, 455, [225, 600]], # Przeciwnik na podłodze
#   [450, 150, [400, 500]], # Przeciwnik na platformie
#   [1550, 455, [1500, 1600]], # Przeciwnik w dalszej części gry
# ]

# enemies = create_enemies(enemy_data, 'assets/images/monster.png')


# def create_castle(x, y, width, height, image_path)
#   Image.new(image_path, x: x, y: y, width: width, height: height)
# end

# castle = create_castle(3750, 324, 144, 176, 'assets/images/castle.png')

# # Funkcja do tworzenia platform z predefiniowanych pozycji
# def create_platforms(platform_data, image_path)
#   platform_data.map do |data|
#     x, y, width, height = data
#     Image.new(image_path, x: x, y: y, width: width, height: height)
#   end
# end

# platform_data = [ # x, y, width, height
#   [225, 325, 50, 50], # Pierwsza platforma
#   [350, 325, 50, 50], # Druga platforma
#   [390, 325, 50, 50], # Trzecia platforma
#   [550, 325, 50, 50],
#   [400, 200, 50, 50],
#   [450, 200, 50, 50],
#   [1500, 200, 50, 50],
#   [1550, 200, 50, 50],
#   [2550, 325, 50, 50],
#   [2700, 200, 50, 50],
#   [2750, 200, 50, 50],
#   [2800, 200, 50, 50],
#   [3000, 200, 50, 50],
#   [3050, 200, 50, 50]
# ]

# # Tworzenie platform
# platforms = create_platforms(platform_data, 'assets/images/brick_block.png')

# # tworzenie tub
# def create_tubes(tube_data, tube_image, tube_lower_image, plant_image, tubes_with_plants)
#   tubes = []
#   tube_data.each_with_index do |data, index|
#     x, y, height = data
#     tube_upper = Image.new(tube_image, x: x, y: y, width: 76, height: 50)
#     tube_lower = Image.new(tube_lower_image, x: x, y: y + 50, width: 76, height: height - 50)
#     plant = nil
#     # Dodaj roślinę tylko do wybranych tub
#     if tubes_with_plants.include?(index)
#       plant = Sprite.new(plant_image, x: x + 20, y: y - 40, width: 30, height: 40, clip_width: 16, time: 100,
#         animations: {
#           closed: 0..0,
#           open: 0..1
#         }
#       )
#       plant.play animation: :open, loop: true # Animacja rośliny w pętli
#     end

#     tubes << { upper: tube_upper, lower: tube_lower, plant: plant, y_top: y }
#   end
#   tubes
# end

# # Dane o tubach (x, y, wysokość)
# tube_data = [
#   [775, 400, 150],    # Pierwsza tuba
#   [1050, 310, 240],   # Druga tuba
#   [1600, 350, 200],   # Trzecia tuba
#   [1800, 450, 100],   # Czwarta tuba
#   [2000, 450, 100],   # Piąta tuba
#   [2200, 450, 100],   # Szósta tuba
#   [3200, 450, 100],   # Siódma tuba
#   [3400, 450, 100]    # Ósma tuba
# ]
# # W których tubach mają być roślinki
# tubes_with_plants = [3, 4, 5, 7]

# # Tworzenie tub
# tubes = create_tubes(tube_data, 'assets/images/tube.png', 'assets/images/tube_lower.png', 'assets/images/plant.png', tubes_with_plants)

# # Funkcja do tworzenia podłogi z segmentami i dziurami
# def create_floor(start_x, y, segments, segment_width, gap_indexes, image_path)
#   floor = []
#   segments.times do |i|
#     unless gap_indexes.include?(i) # Jeśli indeks jest w dziurach, pomiń
#       floor << Image.new(image_path, x: start_x + i * segment_width, y: y, width: segment_width, height: 100)
#     end
#   end
#   floor
# end

# # Tworzenie podłogi z dziurami
# floor_segments = create_floor(0, 500, 100, 50, [ 23, 24, 25, 50, 51, 52, 53, 54, 55, 56, 57, 58], 'assets/images/grass.png') # Dziury w 4., 8. i 13. segmencie

# def create_coins(coin_data, image_path)
#   coin_data.map do |x, y|
#     Image.new(image_path, x: x, y: y, width: 30, height: 30)
#   end
# end

# coin_data = [
#   [300, 335],
#   [435, 130],
#   [600, 130],
#   [475, 335],
#   [1535, 130],
#   [1925, 300], # tuby 
#   [2125, 300],
#   [2735, 130], # wysoko blisko siebie
#   [2785, 130],
#   [3015, 275],
#   [3065, 275],
#   [3035, 130],
#   [3325, 300]
# ]

# coins = create_coins(coin_data, 'assets/images/coin.png')

# $score = 0 # Zmienna do zliczania punktów
# lives = 3 # Zmienna żyć

# initial_position = [50, 455] # początkowe współrzędne Mario
# initial_floor_positions = floor_segments.map(&:x)
# initial_tube_positions = tube_data.map { |data| [data[0], data[0]] }
# initial_platform_positions = platform_data.map { |data| data[0] }
# initial_coins_position = coin_data.map { |x, y| [x, y] }
# initial_enemy_positions = enemy_data.map { |data| [data[0], data[1]] }



# def reset_game(mario, background, floor_segments, platforms, tubes, initial_position, initial_floor_positions, initial_tube_positions, 
#   initial_platform_positions, castle, initial_coins_position, coins, score_text, initial_enemy_positions, enemies)
#   # Reset pozycji Mario
#   mario.x, mario.y = initial_position

#   # Reset tła
#   background.x = 0

#   # Reset podłogi
#   floor_segments.each_with_index do |segment, i|
#     segment.x = initial_floor_positions[i] 
#   end

#   # Reset platform
#   platforms.each_with_index do |platform, i|
#     platform.x = initial_platform_positions[i]
#   end

#   # Reset tub
#   tubes.each_with_index do |tube, i|
#     tube[:upper].x, tube[:lower].x = initial_tube_positions[i]
#     tube[:plant].x = initial_tube_positions[i][0] + 20 if tube[:plant]
#   end

#   # Reset potworków
#   enemies.each_with_index do |enemy, i|
#     enemy[:sprite].x, enemy[:sprite].y = initial_enemy_positions[i] # Reset pozycji
#     enemy[:direction] = :right  # Reset kierunku
#     enemy[:alive] = true  # Potwór wciąż żywy
#   end

#   # # Reset potworków
#   # enemies.each_with_index do |enemy, i|
#   #   if enemy[:alive] == false
#   #     enemy[:sprite] = Sprite.new('assets/images/monster.png', width: 50, height: 50, clip_width: 16, time: 100)
#   #   end
#   #   enemy[:sprite].x, enemy[:sprite].y = initial_enemy_positions[i] # Reset pozycji
#   #   enemy[:direction] = :right  # Reset kierunku
#   #   enemy[:alive] = true  # Potwór wciąż żywy
#   # end

#   # Reset zamku
#   castle.x = 3750

#   # Reset coins 
#   coins.each_with_index do |coin, i|
#     coin.x, coin.y = initial_coins_position[i]
#   end

#   # Reset punktów
#   $score = 0
#   score_text.text = "Score: #{$score}"
# end

# # Zmienne ruchu
# velocity_y = 0
# gravity = 1
# jump_strength = -20
# is_jumping = false
# speed = 5

# #ruch tła
# background_scroll_speed = 5

# # Obsługa klawiatury
# on :key_held do |event|
#   case event.key
#   when 'left'
#     mario.play animation: :walk, loop: false, flip: :horizontal
#     if mario.x > 0
#       mario.x -= speed 
#     end
#   when 'right'
#         mario.play animation: :walk, loop: false
#         if mario.x < (Window.width - 250)
#           mario.x += speed 
#         else
#           if (background.x - Window.width) > -background.width
#           background.x -= speed
#           floor_segments.each { |segment| segment.x -= background_scroll_speed }
#           platforms.each { |platform| platform.x -= background_scroll_speed } # Dodane przesuwanie platform
#           tubes.each do |tube|
#             tube[:upper].x -= background_scroll_speed
#             tube[:lower].x -= background_scroll_speed
#             if tube[:plant] # Sprawdzenie, czy roślina istnieje
#               tube[:plant].x -= background_scroll_speed
#             end
#           end
#           enemies.each do |enemy|
#             enemy[:sprite].x -= background_scroll_speed
#           end
#           castle.x -= background_scroll_speed
#           coins.each do |coin|
#             coin.x -= background_scroll_speed
#           end

#         end
#     end
#   when 'space'
#     if !is_jumping
#       velocity_y = jump_strength
#       is_jumping = true
#       mario.play animation: :jump, loop: false # Animacja skoku
#     end
#   end
# end

# lives_text = Text.new("Lives: #{lives}", x: 10, y: 10, size: 20, color: 'white')
# score_text = Text.new("Score: #{$score}", x: 100, y: 10, size: 20, color: 'white')

# update do
#   # Grawitacja: zmiana prędkości w pionie i aktualizacja pozycji
#   velocity_y += gravity
#   mario.y += velocity_y

#   lives_text.text = "Lives: #{lives}" # Aktualizacja liczby żyć
#   score_text.text = "Score: #{$score}" # Zbieranie punktow - tekst

#   if mario.y > 600 # Mario wpada do dziury
#     lives -= 1
#     if lives > 0
#       reset_game(mario, background, floor_segments, platforms, tubes, initial_position, initial_floor_positions, initial_tube_positions, 
#       initial_platform_positions, castle, initial_coins_position, coins, score_text, initial_enemy_positions, enemies)
#     else
#       game_over_image = Image.new('assets/images/game_over.png', x: 0, y: 0, width: Window.width, height: Window.height)
#       sleep(3)
#       #Window.close
#     end
#   end

#   enemies.each do |enemy|
#     next unless enemy[:alive] # Jeśli przeciwnik martwy, pomijamy


#     # Ruch przeciwnika
#     if enemy[:direction] == :right
#       if enemy[:initial_x] + enemy[:sprite].x + enemy[:sprite].width < enemy[:range][1]
#         enemy[:sprite].x += enemy[:speed]
#       else
#         enemy[:direction] = :left
#       end
#     elsif enemy[:direction] == :left
#       if enemy[:initial_x] + enemy[:sprite].x > enemy[:range][0]
#         enemy[:sprite].x -= enemy[:speed]
#       else
#         enemy[:direction] = :right
#       end
#     end
  
  
#     # Kolizje z Mario
#     if mario.x < enemy[:sprite].x + enemy[:sprite].width &&
#        mario.x + mario.width > enemy[:sprite].x &&
#        mario.y < enemy[:sprite].y + enemy[:sprite].height &&
#        mario.y + mario.height > enemy[:sprite].y
  
#       if mario.y + mario.height - 10 < enemy[:sprite].y # Skok na przeciwnika
#         enemy[:alive] = false
#         enemy[:sprite].play animation: :die, loop: false
#         #enemy[:sprite].remove # Usunięcie potworka
#         $score += 200
#         score_text.text = "Score: #{$score}"

#       # Usuwamy przeciwnika z ekranu
#       enemy[:sprite].remove 
#       enemies.delete(enemy) # Usuwamy z listy przeciwników

#       else # Kontakt boczny
#         lives -= 1
#         if lives > 0
#           reset_game(mario, background, floor_segments, platforms, tubes, initial_position, initial_floor_positions,
#                      initial_tube_positions, initial_platform_positions, castle, initial_coins_position, coins, score_text, initial_enemy_positions, enemies)
#         else
#           game_over_image = Image.new('assets/images/game_over.png', x: 0, y: 0, width: Window.width, height: Window.height)
#           sleep(3)
#           Window.close
#         end
#       end
#     end
#   end
  

#   # kolizja z platformami
#   platforms.each do |platform|
#     if mario.y + mario.height >= platform.y &&
#       mario.y + mario.height <= platform.y + 15 && # Tolerancja kolizji
#       mario.x + mario.width > platform.x &&
#       mario.x < platform.x + platform.width &&
#       velocity_y >= 0 # Tylko jeśli Mario opada
#      mario.y = platform.y - mario.height
#      velocity_y = 0
#      is_jumping = false
#      break # Zatrzymujemy pętlę, aby uniknąć nadpisania pozycji
#     end
#     # Kolizja z dołem platformy
#     if mario.y <= platform.y + platform.height &&
#       mario.y >= platform.y + platform.height - 15 && # Tolerancja dla dołu platformy
#       mario.x + mario.width > platform.x &&
#       mario.x < platform.x + platform.width &&
#       velocity_y < 0 # Tylko jeśli Mario skacze w górę
#      mario.y = platform.y + platform.height
#      velocity_y = 0 # Zatrzymujemy ruch w górę
#      break
#     end
#     # Kolizja z lewej strony platformy
#     if mario.x + mario.width >= platform.x &&
#       mario.x + mario.width <= platform.x + 10 && # Tolerancja kolizji z lewej
#       mario.y + mario.height > platform.y &&
#       mario.y < platform.y + platform.height
#     mario.x = platform.x - mario.width # Zatrzymanie Mario przed platformą
#     end
#     # Kolizja z prawej strony platformy
#     if mario.x <= platform.x + platform.width &&
#       mario.x >= platform.x + platform.width - 10 && # Tolerancja kolizji z prawej
#       mario.y + mario.height > platform.y &&
#       mario.y < platform.y + platform.height
#     mario.x = platform.x + platform.width # Zatrzymanie Mario po drugiej stronie
#     end
#   end

#    # Kolizja z tubami 
#    tubes.each do |tube|
#     # Góra tuby
#     if mario.y + mario.height >= tube[:upper].y &&
#        mario.y + mario.height <= tube[:upper].y + 15 &&
#        mario.x + mario.width > tube[:upper].x &&
#        mario.x < tube[:upper].x + tube[:upper].width &&
#        velocity_y >= 0 # Opadający Mario
#       mario.y = tube[:upper].y - mario.height
#       velocity_y = 0
#       is_jumping = false
#       break
#     end
#     # Lewa strona tuby
#     if mario.x + mario.width > tube[:lower].x &&
#        mario.x < tube[:lower].x + 10 && # Tolerancja kolizji po lewej
#        mario.y + mario.height > tube[:lower].y &&
#        mario.y < tube[:lower].y + tube[:lower].height
#       mario.x = tube[:lower].x - mario.width # Zatrzymanie Mario przed tubą
#     end
#     # Prawa strona tuby
#     if mario.x < tube[:lower].x + tube[:lower].width &&
#        mario.x + mario.width > tube[:lower].x + tube[:lower].width - 10 && # Tolerancja
#        mario.y + mario.height > tube[:lower].y &&
#        mario.y < tube[:lower].y + tube[:lower].height
#       mario.x = tube[:lower].x + tube[:lower].width # Zatrzymanie Mario po drugiej stronie
#     end
#     # Kolizja z rośliną
#     if tube[:plant] && mario.x < tube[:plant].x + tube[:plant].width &&
#       mario.x + mario.width > tube[:plant].x &&
#       mario.y < tube[:plant].y + tube[:plant].height &&
#       mario.y + mario.height > tube[:plant].y
#      puts "Mario traci życie przez kwiatka!"
#      lives -= 1
#      if lives > 0
#        reset_game(mario, background, floor_segments, platforms, tubes, initial_position, initial_floor_positions, initial_tube_positions, 
#        initial_platform_positions, castle, initial_coins_position, coins, score_text, initial_enemy_positions, enemies)
#      else
#        game_over_image = Image.new('assets/images/game_over.png', x: 0, y: 0, width: Window.width, height: Window.height)
#        sleep(3)
#        Window.close
#      end
#    end
#   end

#   # Kolizja Mario z monetami
#   coins.each do |coin|
#     if mario.x < coin.x + coin.width &&
#        mario.x + mario.width > coin.x &&
#        mario.y < coin.y + coin.height &&
#        mario.y + mario.height > coin.y
#       coins.delete(coin)  # Usunięcie monety z listy
#       coin.remove         # Usunięcie monety z ekranu
#       $score += 100       # Dodanie punktów
#       score_text.text = "Score: #{$score}"
#     end
#   end

#   # Sprawdzanie kolizji z podłogą
#   on_floor = false
#   floor_segments.each do |segment|
#     if mario.y + mario.height >= segment.y &&
#        mario.y + mario.height <= segment.y + 30 && # Tolerancja kolizji
#        mario.x + mario.width > segment.x &&
#        mario.x < segment.x + segment.width 
#        mario.y = segment.y - mario.height
#        velocity_y = 0
#        is_jumping = false
#       #mario.play animation: :idle, loop: true
#        on_floor = true
#     end
#   end

#   if !on_floor
#     if mario.y > 600
#       velocity_y = -15
#       #puts "Game Over! Mario fell into a hole!"
#       #sleep(2)
#       #Window.close
#     end
#   end

#   # Sprawdzanie kolizji Mario z zamkiem
#   if mario.x + mario.width > castle.x &&
#     mario.x < castle.x + castle.width &&
#     mario.y + mario.height > castle.y &&
#     mario.y < castle.y + castle.height

#    # Wyświetlenie obrazka "YOU WIN" i zakończenie gry
#    you_win_image = Image.new('assets/images/you_win.png', x: 0, y: 0, width: Window.width, height: Window.height)
#    sleep(3) # Wyświetlanie ekranu przez 3 sekundy
#    #Window.close
#  end

# end

# show