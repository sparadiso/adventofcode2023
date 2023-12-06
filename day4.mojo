from algorithm.sort import sort

@value
struct Card(CollectionElement, Stringable):
    var card_number: Int
    var copies: Int
    var winning_numbers: DynamicVector[Int]
    var user_numbers: DynamicVector[Int]

    fn __init__(inout self: Self, id: Int, winning: DynamicVector[Int], user: DynamicVector[Int]):
        self.winning_numbers = winning
        self.user_numbers = user
        self.card_number = id
        self.copies = 1

        sort(self.winning_numbers)
        sort(self.user_numbers)

    def matches(self: Self) -> Int:
        var matches = 0
        for i in range(len(self.user_numbers)):
            for j in range(len(self.winning_numbers)):
                if self.user_numbers[i] == self.winning_numbers[j]:
                    matches += 1
                
                if self.user_numbers[i] < self.winning_numbers[j]:
                    break

        return matches

    def value(self: Self) -> Int:
        var value = 0
        for i in range(len(self.user_numbers)):
            for j in range(len(self.winning_numbers)):
                if self.user_numbers[i] == self.winning_numbers[j]:
                    value = value * 2

                    if value == 0:
                        value = 1
                
                if self.user_numbers[i] < self.winning_numbers[j]:
                    break

        return value

    fn __str__(self: Self) -> String:
        var buffer = String()

        buffer += "Card " + str(self.card_number) + "["+self.copies+"]: "

        for i in range(len(self.winning_numbers)):
            buffer += self.winning_numbers[i] + String(" ")

        buffer += "| "

        for i in range(len(self.user_numbers)):
            buffer += self.user_numbers[i] + String(" ")

        return buffer

def parse_card(line: String) -> Card:
    var winning_numbers = DynamicVector[Int]()
    var user_numbers = DynamicVector[Int]()

    let winning_dump = line.split(":")[1].split("|")[0].split(" ")
    let user_dump = line.split(":")[1].split("|")[1].split(" ")

    for i in range(len(winning_dump)):
        try:
            let v = atol(winning_dump[i])
            winning_numbers.append(v)
        except e:
            pass

    for i in range(len(user_dump)):
        try:
            let v = atol(user_dump[i])
            user_numbers.append(v)
        except e:
            pass

    let tmp = line.split(":")[0].split(" ")
    let card_id: Int = atol(tmp[len(tmp)-1])
    return Card(card_id, winning_numbers, user_numbers)

def to_str(lst: DynamicVector[String])->String:
    var buffer = String()
    for i in range(len(lst)):
        buffer += "'" + lst[i] + "', "
    return buffer

def part1_unit_test():
    var total = 0

    with open("day4_test.input", 'r') as f:
        let lines = f.read().split("\n")
        for i in range(len(lines)):
            let card = parse_card(lines[i])
            total += card.value()
        
    print(total)

    if total != 13:
        raise Error("Expected 13 got " + str(total))

def part1():
    var total = 0

    with open("day4.input", 'r') as f:
        let lines = f.read().split("\n")
        for i in range(len(lines)):
            let card = parse_card(lines[i])
            total += card.value()
        
    print(total)

def part2_unit_test():
    let total = part2("day4_test.input")

    if total != 30:
        raise Error("Expected 30 got " + str(total))

def part2(fname: String)->Int:
    var total = 0

    var cards = DynamicVector[Card]()
    with open(fname, 'r') as f:
        let lines = f.read().split("\n")
        for i in range(len(lines)):
            cards.append(parse_card(lines[i]))
        
    for i in range(len(cards)):
        # Evaluate the card
        let n_matches = cards[i].matches()
        
        # Copy the next 'n_matches' cards
        for j in range(i+1, i+1+n_matches):
            cards[j].copies += cards[i].copies

    for i in range(len(cards)):
        total += cards[i].copies

    return total

def main():
    part2_unit_test()
    print(part2("day4.input"))
    # part1()
