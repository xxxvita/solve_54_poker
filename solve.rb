debug = false
# Задача

# Вид сдачи из файла (по 5 карт на руки)
# 8C TS KC 9H 4S 7D 2S 5D 3S AC
# 5C AD 5D AC 9C 7C 5H 8D TD KS
# 3H 7H 6S KC JS QH TD JC 2D 8S

# s - пики; c - трефы; h - червы; d - бубны. Без разницы как обозначаются масти. Важно одно: одинаковые ли
# масти на руках или нет.

# Каждой комбинации дам оценочный бал, начиная с самой сильной:
price = {
    :royal_flash => 1,
    :street_flash => 2,
    :kare => 3,
    :full_house => 4,
    :flash => 5,
    :street => 6,
    :set => 7,
    :two_pair => 8,
    :pair => 9,
    :high_card => 10
}

# преобразую руку в 2 массива
# h - [hands] массив карт по достоинству отсортированный по возрастанию
# m - [масти] массив мастей не имеет значения как расположены
def prepare_hand(hand)
  # Хеш замены символов в картах на числа
  card_symb_value = {
      "2" => 2,
      "3" => 3,
      "4" => 4,
      "5" => 5,
      "6" => 6,
      "7" => 7,
      "8" => 8,
      "9" => 9,
      "T" => 10,
      "J" => 11,
      "Q" => 12,
      "K" => 13,
      "A" => 14
  }

  h = [] # достоинства
  m = [] # масти

  # все буквы находим, заменяем на циферки, сразу перекладывая в массив
  hand.gsub(/([\w]{1})([\w]{1})( |$)/) do
    h << card_symb_value[$1]
    m << $2
  end

  return h.sort, m
end

def combo(h, m)
  # по умолчанию у нас такая комбинация, если нет другого
  result = :high_card
  # при спорных ситуациях (равные комбинации)
  # требуется сравнить старшие карты комбинаций,
  # если и они равны, то старшие карты раздачи
  high_card = {
      :high_card_comb => nil,
      :high_card => nil
  }

  # Эти комбинации можно получить быстро и в 1 дейтсвие.
  comb_flash = false
  comb_street = true # заранее удовлетворяет, потом испортится, если не так
  comb_street_flash = false
  comb_royal_flash = false

  # Флеш: число уникальных мастей равно 1
  comb_flash = true if m.uniq.size == 1
  # Стрит: каждый следующий элемент больше предыдущего на 1
  h.each_with_index{|x, i| i > 0 && comb_street &= (x - h[i - 1]) == 1}
  # Стрит-флеш
  comb_street_flash = true if comb_flash && comb_street
  # Флеш-роял
  comb_royal_flash = true if comb_street_flash && h.max == 14 # Туз

  # Осталось определить всего несколько комбинаций
  comb_h = {
    [1, 1, 1, 1, 1] => :high_card, # хеш комбинаций с количеством парных карт
    [2, 1, 1, 1] => :pair,         # и оставшимися не парными. Буду брать
    [2, 2, 1] => :two_pair,        # в цикле каждую комбинацию и проверять
    [3, 2] => :full_house,         # является ли имеющаяся на руках такой же.
    [4, 1] => :kare,               # Если да, то определять закончили.
    [3, 1, 1] => :set              #
  }

  # Всё это имеет смысл, если ещё нет никакой комбинации
  # Наша раздача в виде комбинации дублей с остатком
  h_uniq = h.uniq
  h_uniq_count = []
  h_uniq.each{|x| h_uniq_count << h.count(x)}
  # Наша раздача в виде связи достоинства кары и её количества
  h_val_count = Hash.new
  h.each {|x| h_val_count[x] = h.count(x)}

  if !comb_street && !comb_flash &&
    !comb_royal_flash && !comb_street_flash
    comb_h.each do |key, value|
      permut = key.permutation(key.size)

      permut.each do |p|
        result = value if p == h_uniq_count

        # получение старшей карты
        case
          when [:full_house, :high_card].include?(result) then
            high_card[:high_card_comb] = h.max
            high_card[:high_card] = high_card[:high_card_comb]
          else
            high_card[:high_card_comb] = h_val_count.max_by{|val, count| count != 1 ? val : 1}[0]
            high_card[:high_card] = h_val_count.max_by{|val, count| count == 1 ? val : 1}[0]
        end
      end # permut.each do |p|
    end # comb_h.each do |key, value|
  elsif comb_royal_flash then result = :royal_flash
  elsif comb_street_flash then result = :street_flash
  elsif comb_street then result = :street
  elsif comb_flash then result = :flash
  end

  # Если старшая карта не определена
  if high_card[:high_card_comb].nil?
    high_card[:high_card_comb] = h.max
    high_card[:high_card] = high_card[:high_card_comb]
  end

  return result, high_card
end

if !debug
cnt = 0
i = 0
hands = File.open("poker.txt", "r:UTF-8").readlines

hands.each do |hand|
  win = false
  i += 1

  puts "Сдача №#{i}"

  symb_h = hand[0..13]
  symb_h1 = hand[15..28]

  h, m = prepare_hand(symb_h.chomp)
  h1, m1 = prepare_hand(symb_h1.chomp)

  result, high_card = combo(h, m)
  result1, high_card1 = combo(h1, m1)

  puts "Первая рука: #{symb_h}: #{result}"
  puts "Вторая рука: #{symb_h1}: #{result1}"

  if price[result] < price[result1]
    win = true
  elsif price[result] == price[result1]
    if high_card[:high_card_comb] > high_card1[:high_card_comb]
      win = true
    elsif high_card[:high_card_comb] == high_card1[:high_card_comb]
      win = true if high_card[:high_card] > high_card1[:high_card]
    end
  end

  if win
    puts "Выиграла 1 рука"
    cnt += 1
  end

  puts "----------------------------------------------------------"

end

puts cnt
end

if debug

  h, m = prepare_hand("8C TS KC 9H 4S")
  h1, m1 = prepare_hand("7D 2S 5D 3S AC")
  result, high_card = combo(h, m)
  result1, high_card1 = combo(h1, m1)

  puts result, high_card
  puts result1, high_card1
  puts price[result], price[result1]
end