from helpers import join, max, min

# Small bag with cubes
# Colors: R, G, B
# Each game, he hides a random # of cubes of each color
# Goal: figure out info about the number of cubes of each color
# 5 games``


@value
struct Game(CollectionElement, Stringable):
    var id: Int

    var red: DynamicVector[Int]
    var green: DynamicVector[Int]
    var blue: DynamicVector[Int]

    fn __str__(self: Self) -> String:
        return ""+str(self.id)+": " + "[R: (" +join(", ", self.red)+ "), G: (" + join(", ", self.green) + "), B: (" + join(", ", self.blue) + ")]"

def __parse_roll(roll: String) -> Tuple[Int, Int, Int]:
    # Returns (R, G, B)

    var red: Int = 0
    var green: Int = 0
    var blue: Int = 0

    groups = roll.split(",")
    for i in range(len(groups)):
        let s: String = ""

        substrings = groups[i].split(" ")
        count = atol(substrings[1])
        color = substrings[2]

        if color == "red":
            red = count
        if color == "blue":
            blue = count
        if color == "green":
            green = count

    return Tuple(red, green, blue)

def load_games(input_path: String) -> DynamicVector[Game]:
    var games = DynamicVector[Game]()

    with open(input_path, 'r') as f:
        let lines: DynamicVector[String] = f.read().split("\n")
        for i in range(len(lines)):
            var red = DynamicVector[Int]()
            var green = DynamicVector[Int]()
            var blue = DynamicVector[Int]()

            # Game 1: 2 blue, 4 green; 7 blue, 1 red, 14 green; 5 blue, 13 green, 1 red; 1 red, 7 blue, 11 green

            # 2 blue, 4 green
            let rolls = lines[i].split(":")[1].split(";")
            for j in range(len(rolls)):
                let rgb = __parse_roll(rolls[j])

                red.append(rgb.get[0, Int]())
                green.append(rgb.get[1, Int]())
                blue.append(rgb.get[2, Int]())

            let game = Game(i+1, red^, green^, blue^)
            games.append(game)

    return games

def part1(games: DynamicVector[Game]):
    r_max = 12
    g_max = 13
    b_max = 14
    var total = 0
    for i in range(len(games)):
        if max(games[i].red) <= r_max and 
           max(games[i].blue) <= b_max and 
           max(games[i].green) <= g_max:

            total += games[i].id

    print(total)

def __power(rgb: Tuple[Int, Int, Int]) -> Int:
    return rgb.get[0, Int]() * rgb.get[1, Int]() * rgb.get[2, Int]()

def __min_set(game: Game) -> Tuple[Int, Int, Int]:
    return Tuple(max(game.red), max(game.green), max(game.blue))

def part2(games: DynamicVector[Game]):
    var total = 0

    for i in range(len(games)):
        total += __power(__min_set(games[i]))

    print(total)


def main():
    let games = load_games("day2.input")
    # part1(games)
    part2(games)
